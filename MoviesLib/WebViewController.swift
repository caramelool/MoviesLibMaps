//
//  WebViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 04/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var url: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webpageURL = URL(string: url)
        let request = URLRequest(url: webpageURL!)
        webView.loadRequest(request)
    }

    @IBAction func executarJS(_ sender: UIBarButtonItem) {
        webView.stringByEvaluatingJavaScript(from: "alert('Rodando JavaScript na WebView')")
    }
    
    @IBAction func fechar(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

extension WebViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        indicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let url = request.url!.absoluteString
        print(">>>>>>    ", url)
        if url.range(of: "ads") != nil {
            return false
        }
        
        return true
    }
}
