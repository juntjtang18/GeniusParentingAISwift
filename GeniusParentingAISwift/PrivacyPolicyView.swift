// PrivacyPolicyView.swift

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Last Updated: February 23, 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Parent Genius AI (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our website and iPhone app (the \"Services\"). By using our Services, you agree to the practices described in this Privacy Policy.")

                    section(title: "1. Information We Collect", content: [
                        (subtitle: "a. Personal Information:", text: "We may collect personal information you provide directly to us, including:\n• Name\n• Email address\n• Contact details\n• Account credentials (if applicable)"),
                        (subtitle: "b. Automatically Collected Information:", text: "When you use our Services, we may automatically collect:\n• Device information (e.g., model, OS version)\n• IP address\n• Usage data (e.g., pages viewed, features used)\n• Cookies and similar tracking technologies"),
                        (subtitle: "c. Information from Third Parties:", text: "We may receive information about you from third parties, such as analytics providers or app stores.")
                    ])
                    
                    section(title: "2. How We Use Your Information", content: [
                        (subtitle: nil, text: "We use the information collected to:\n• Provide, maintain, and improve our Services\n• Personalize your experience\n• Send updates, newsletters, and promotional materials (with your consent)\n• Respond to inquiries and provide customer support\n• Monitor and analyze usage for security and optimization\n• Comply with legal obligations")
                    ])

                    section(title: "3. Sharing Your Information", content: [
                        (subtitle: nil, text: "We do not sell or rent your personal information. We may share your data with:\n• Service Providers: Trusted third parties who assist us in operating our Services (e.g., cloud hosting, analytics)\n• Legal Obligations: When required by law, regulation, or legal process\n• Business Transfers: In case of a merger, sale, or acquisition, your information may be transferred to new ownership")
                    ])
                    
                    section(title: "4. Data Security", content: [
                        (subtitle: nil, text: "We implement reasonable security measures to protect your data. While we strive to safeguard your information, no method of transmission over the internet or electronic storage is 100% secure.")
                    ])

                    section(title: "5. Your Choices", content: [
                        (subtitle: "a. Access and Update:", text: "You can access and update your personal information by contacting us at contact@parentgeniusai.com."),
                        (subtitle: "b. Opt-Out:", text: "You can opt out of receiving promotional communications by following the unsubscribe instructions in our emails."),
                        (subtitle: "c. Cookies:", text: "Most browsers allow you to control cookies. Disabling cookies may impact your experience using our Services.")
                    ])
                    
                    section(title: "6. Children’s Privacy", content: [
                        (subtitle: nil, text: "Our Services are designed for parents and are not intended for children under 13. We do not knowingly collect personal information from children. If we discover that a child under 13 has provided personal data, we will delete it promptly.")
                    ])
                    
                    section(title: "7. Third-Party Links", content: [
                        (subtitle: nil, text: "Our Services may contain links to third-party websites or apps. We are not responsible for their privacy practices. Please review their privacy policies before providing any personal information.")
                    ])

                    section(title: "8. Changes to This Privacy Policy", content: [
                        (subtitle: nil, text: "We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy on our website and app. Your continued use of the Services after updates signifies your acceptance of the revised policy.")
                    ])

                    section(title: "9. Contact Us", content: [
                        (subtitle: nil, text: "GNM399 Ventures Corp.\n2112 W Broadway Unit 208\nVancouver, BRITISH COLUMBIA V6K 2C8\nCanada\nEmail: support@geniusParentingAI.ca")
                    ])
                    
                    Text("Thank you for trusting Parent Genius AI. We are committed to empowering parents while respecting your privacy.")
                        .padding(.top)

                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func section(title: String, content: [(subtitle: String?, text: String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            ForEach(content, id: \.text) { item in
                VStack(alignment: .leading, spacing: 5) {
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .fontWeight(.semibold)
                    }
                    Text(item.text)
                }
            }
        }
    }
}
