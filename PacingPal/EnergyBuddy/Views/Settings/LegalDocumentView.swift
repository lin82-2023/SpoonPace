// PacingPal
// LegalDocumentView.swift
// 法律文档页面 - Privacy Policy / Terms of Service

import SwiftUI
import WebKit

struct LegalDocumentView: View {
    let title: String
    let filename: String

    @State private var isLoading = true
    @State private var loadingError: String?

    var body: some View {
        ZStack {
            WebView(
                htmlFilename: filename,
                onLoadingStart: {
                    isLoading = true
                },
                onLoadingFinish: {
                    isLoading = false
                },
                onLoadingError: { error in
                    isLoading = false
                    loadingError = error
                }
            )

            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }

            if let error = loadingError {
                ContentUnavailableView {
                    Label(String(localized: "Failed to Load"), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - WebView
struct WebView: UIViewRepresentable {
    let htmlFilename: String
    let onLoadingStart: () -> Void
    let onLoadingFinish: () -> Void
    let onLoadingError: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = .link

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .systemBackground
        webView.isOpaque = true
        webView.scrollView.alwaysBounceVertical = true
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: htmlFilename, withExtension: "html") else {
            onLoadingError(String(localized: "Document not found"))
            return
        }

        do {
            let htmlString = try String(contentsOf: url, encoding: .utf8)
            webView.loadHTMLString(htmlString, baseURL: url.deletingLastPathComponent())
        } catch {
            onLoadingError(error.localizedDescription)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLoadingStart: onLoadingStart,
            onLoadingFinish: onLoadingFinish,
            onLoadingError: onLoadingError
        )
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onLoadingStart: () -> Void
        let onLoadingFinish: () -> Void
        let onLoadingError: (String) -> Void

        init(
            onLoadingStart: @escaping () -> Void,
            onLoadingFinish: @escaping () -> Void,
            onLoadingError: @escaping (String) -> Void
        ) {
            self.onLoadingStart = onLoadingStart
            self.onLoadingFinish = onLoadingFinish
            self.onLoadingError = onLoadingError
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingStart()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingFinish()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadingError(error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadingError(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(title: String(localized: "Privacy Policy"), filename: "PrivacyPolicy")
    }
}
