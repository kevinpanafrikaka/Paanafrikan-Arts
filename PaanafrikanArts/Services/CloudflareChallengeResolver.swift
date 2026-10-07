//
//  CloudflareChallengeResolver.swift
//  PaanafrikanArts
//
//  www.artic.edu (CDN d'images IIIF, différent de api.artic.edu) est passé
//  derrière un challenge JS Cloudflare ("Just a moment...", header
//  `cf-mitigated: challenge`) après le 2026-09-14 — vérifié en direct,
//  remplace l'ancien blocage "juste un header Referer manquant".
//
//  Piège vérifié en direct : une fois le challenge résolu dans une
//  WKWebView (cookie `cf_clearance` obtenu), une requête URLSession classique
//  avec ce même cookie recopié continue de recevoir 403. Cloudflare lie
//  visiblement la validité du cookie à l'empreinte réseau du client (TLS/
//  user-agent du moteur WebKit), pas juste au cookie. Impossible donc de
//  "récupérer" la session pour l'utiliser hors de la WebView.
//
//  Solution : ne jamais quitter le contexte WebKit. Une WKWebView unique et
//  persistante (attachée, quasi invisible, à la fenêtre de l'app) charge
//  une page sur www.artic.edu une fois pour laisser le challenge se
//  résoudre (~20s sur ce réseau), puis chaque image est récupérée en
//  exécutant un `fetch()` JS *dans cette même page* (même session/empreinte
//  réseau), converti en base64 et renvoyé à Swift.
//

import Foundation
import WebKit
import UIKit

@MainActor
final class CloudflareChallengeResolver {
    static let shared = CloudflareChallengeResolver()

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        attach(webView)
        return webView
    }()

    private var readyTask: Task<Void, Never>?

    private init() {}

    /// Récupère les octets de l'image à `url` en passant par le contexte JS
    /// de la WKWebView (voir explication en tête de fichier). `nil` si le
    /// challenge n'a pas pu être résolu ou si le fetch JS échoue.
    func fetchImageData(for url: URL) async -> Data? {
        await ensureReady()

        // `evaluateJavaScript` n'attend PAS une Promise renvoyée par une
        // IIFE async (elle essaie de "bridger" l'objet Promise lui-même
        // vers Swift → WKErrorDomain Code=5 "unsupported type", vérifié en
        // direct). `callAsyncJavaScript` est l'API faite pour ça : le
        // corps ci-dessous est exécuté comme le corps d'une fonction async
        // déjà, pas besoin de wrapper `(async () => {...})()`.
        let functionBody = """
        try {
            const resp = await fetch(url, { credentials: 'include' });
            if (!resp.ok) return null;
            const buf = await resp.arrayBuffer();
            const bytes = new Uint8Array(buf);
            let binary = '';
            const chunkSize = 0x8000;
            for (let i = 0; i < bytes.length; i += chunkSize) {
                binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunkSize));
            }
            return btoa(binary);
        } catch (e) {
            return null;
        }
        """

        do {
            let result = try await webView.callAsyncJavaScript(
                functionBody,
                arguments: ["url": url.absoluteString],
                contentWorld: .page
            )
            guard let base64 = result as? String else { return nil }
            return Data(base64Encoded: base64)
        } catch {
            return nil
        }
    }

    /// Charge une fois `https://www.artic.edu/` dans la WKWebView partagée
    /// et attend l'obtention du cookie `cf_clearance`. Les appels
    /// concurrents partagent la même tentative.
    private func ensureReady() async {
        if let readyTask {
            await readyTask.value
            return
        }
        let task = Task { await performReady() }
        readyTask = task
        await task.value
    }

    private func performReady() async {
        webView.load(URLRequest(url: URL(string: "https://www.artic.edu/")!))

        // Vérifié en direct (Safari réel dans le simulateur, 2026-09-16) :
        // le challenge managé Cloudflare prend environ 20s à se résoudre
        // tout seul sur ce réseau, pas quelques secondes comme d'habitude.
        let deadline = Date().addingTimeInterval(35)
        while Date() < deadline {
            if await hasClearanceCookie() { return }
            try? await Task.sleep(for: .milliseconds(500))
        }
    }

    private func hasClearanceCookie() async -> Bool {
        let cookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        return cookies.contains { $0.name == "cf_clearance" }
    }

    private func attach(_ webView: WKWebView) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else { return }
        webView.alpha = 0.01
        webView.isUserInteractionEnabled = false
        window.insertSubview(webView, at: 0)
    }
}
