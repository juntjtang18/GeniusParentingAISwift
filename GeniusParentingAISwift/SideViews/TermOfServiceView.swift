// TermsOfServiceView.swift

import SwiftUI

struct TermsOfServiceView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Effective Date: July 12, 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Welcome to Genius Parenting AI (\"we,\" \"our,\" or \"us\"). These Terms of Service (\"Terms\") govern your access to and use of our website, https://www.geniusparentingAI.ca (the \"Website\"), and any services, content, and features provided by GNM399 Ventures Corp.")
                    
                    Text("By accessing or using our Website, you agree to comply with and be bound by these Terms. If you do not agree with any part of these Terms, please do not use our Website.")

                    section(title: "1. Use of Our Website", content: "You may use our Website for personal, non-commercial purposes. You agree not to:\n• Violate any applicable laws or regulations.\n• Use the Website for fraudulent or unlawful purposes.\n• Interfere with or disrupt the security or operation of the Website.\n• Copy, distribute, or modify any part of our Website without permission.")
                    
                    section(title: "2. Intellectual Property", content: "All content, trademarks, logos, and intellectual property on the Website belong to GNM399 Ventures Corp. or its licensors. Unauthorized use of any content is strictly prohibited.")

                    section(title: "3. User Content", content: "If you submit content (e.g., comments, reviews) to the Website, you grant us a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, and distribute such content. You are responsible for ensuring that your content does not violate any third-party rights or laws.")
                    
                    section(title: "4. Disclaimers", content: "The Website and its content are provided \"as is\" without warranties of any kind, express or implied. We do not guarantee that the Website will be error-free, uninterrupted, or free of harmful components.")

                    section(title: "5. Limitation of Liability", content: "To the fullest extent permitted by law, GNM399 Ventures Corp. shall not be liable for any indirect, incidental, or consequential damages resulting from your use of the Website.")
                    
                    section(title: "6. Third-Party Links", content: "Our Website may contain links to third-party websites. We are not responsible for the content or practices of these websites and encourage you to review their terms and policies.")
                    
                    section(title: "7. Termination", content: "We reserve the right to terminate or suspend access to our Website at any time, with or without cause.")

                    section(title: "8. Governing Law", content: "These Terms shall be governed by and construed in accordance with the laws of British Columbia, Canada. Any disputes shall be resolved in the courts of British Columbia.")

                    section(title: "9. Changes to These Terms", content: "We may update these Terms from time to time. Continued use of the Website after any modifications constitutes acceptance of the revised Terms.")

                    section(title: "10. Contact Information", content: "GNM399 Ventures Corp.\n2112 W Broadway Unit 208\nVancouver, BRITISH COLUMBIA V6K 2C8\nCanada\nEmail: support@geniusParentingAI.ca")
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            Text(content)
        }
    }
}
