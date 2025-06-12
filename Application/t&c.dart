import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Stitch Pal!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'These Terms and Conditions govern your use of our platform, which connects shopkeepers and tailors for stitching services. By registering and using our application, you agree to these terms.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('1. Definitions'),
            _buildBulletPoint('Shopkeeper: A user who seeks tailoring services for stitching clothes and fabrics.'),
            _buildBulletPoint('Tailor: A user who provides stitching services to shopkeepers.'),
            _buildBulletPoint('Platform: The Stitch Pal application, which facilitates the connection between shopkeepers and tailors.'),
            _buildBulletPoint('Monthly Bill: A system-generated invoice summarizing transactions and expenses for both users.'),

            _buildSectionTitle('2. User Registration & Accounts'),
            _buildParagraph('Both shopkeepers and tailors must register with accurate details, including contact information and payment details.'),
            _buildParagraph('Users must maintain the confidentiality of their login credentials.'),
            _buildParagraph('Stitch Pal reserves the right to suspend or terminate accounts violating our policies.'),

            _buildSectionTitle('3. Service Usage'),
            _buildParagraph('Shopkeepers can request stitching services from available tailors.'),
            _buildParagraph('Tailors must provide services as per agreed timelines and quality standards.'),
            _buildParagraph('Both parties should communicate clearly about pricing, fabric details, and delivery timelines before confirming an order.'),
            _buildParagraph('Stitch Pal does not guarantee the quality of services but provides a platform for transactions.'),

            _buildSectionTitle('4. Payments & Billing'),
            _buildParagraph('Payments for stitching services must be made through the platform’s approved payment methods.'),
            _buildParagraph('A Monthly Bill will be generated for both users, summarizing completed transactions and expenses.'),
            _buildParagraph('Users must clear their outstanding dues as per the billing cycle.'),
            _buildParagraph('Stitch Pal may charge a commission or service fee, which will be mentioned in the billing statement.'),

            _buildSectionTitle('5. Cancellations & Refunds'),
            _buildParagraph('Shopkeepers can cancel an order before the tailor starts stitching.'),
            _buildParagraph('If a tailor fails to deliver the agreed service, the shopkeeper may request a refund.'),
            _buildParagraph('Refunds will be processed based on Stitch Pal’s refund policy.'),
            _buildParagraph('Disputes will be resolved based on the terms agreed between both parties and subject to platform policies.'),

            _buildSectionTitle('6. User Responsibilities'),
            _buildParagraph('Users must act in good faith, ensuring fair transactions.'),
            _buildParagraph('Tailors must complete services as promised, and shopkeepers must provide required materials and payments timely.'),
            _buildParagraph('Misuse of the platform, including fraudulent transactions, may lead to account suspension.'),

            _buildSectionTitle('7. Dispute Resolution'),
            _buildParagraph('Any disputes should be reported to Stitch Pal’s customer support.'),
            _buildParagraph('The platform will mediate disputes where possible, but final responsibility lies with the users involved in the transaction.'),

            _buildSectionTitle('8. Limitation of Liability'),
            _buildParagraph('Stitch Pal only acts as an intermediary and is not responsible for service quality or delivery.'),
            _buildParagraph('The platform is not liable for any losses, delays, or issues arising from third-party services.'),

            _buildSectionTitle('9. Privacy Policy'),
            _buildParagraph('User data is stored securely and used in accordance with our Privacy Policy.'),
            _buildParagraph('Users consent to the collection and processing of data necessary for platform operations.'),

            _buildSectionTitle('10. Modifications to Terms'),
            _buildParagraph('Stitch Pal reserves the right to modify these terms at any time.'),
            _buildParagraph('Users will be notified of changes and continued use of the platform constitutes acceptance of the new terms.'),

            _buildSectionTitle('11. Contact Information'),
            _buildParagraph('For any questions or concerns regarding these terms, please contact us at:'),
            _buildParagraph('Email: kashishdarji@gmail.com'),
            _buildParagraph('Phone: 9313663001'),

            SizedBox(height: 20),
            Text(
              'By using Stitch Pal, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 5),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Text(text),
    );
  }
}
