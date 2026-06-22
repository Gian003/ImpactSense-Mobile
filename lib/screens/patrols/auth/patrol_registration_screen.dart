import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:impactsense/core/services/api_client.dart';
import 'package:impactsense/core/services/auth_service.dart';
import 'package:impactsense/widgets/app_input_field.dart';
import 'package:impactsense/widgets/role_toggle.dart';

// ── Screen entry point ────────────────────────────────────────────────────────

class PatrolRegistrationScreen extends StatefulWidget {
  const PatrolRegistrationScreen({super.key});

  @override
  State<PatrolRegistrationScreen> createState() =>
      _PatrolRegistrationScreenState();
}

class _PatrolRegistrationScreenState extends State<PatrolRegistrationScreen> {
  // 0 = Sign Up form, 1 = Log In form, 2 = Pending confirmation
  int  _view         = 0;
  bool _loading      = false;
  bool _pwVisible    = false;
  bool _repeatVisible = false;

  // Sign Up fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  // Log In fields (reuse email; separate password)
  final _loginPasswordCtrl = TextEditingController();

  String _submittedEmail = '';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Sign Up submit ────────────────────────────────────────────────────────

  Future<void> _submitRegistration() async {
    final first    = _firstNameCtrl.text.trim();
    final last     = _lastNameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (first.isEmpty || last.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await ApiClient.post('patrol/register-request', {
        'first_name'            : first,
        'last_name'             : last,
        'email'                 : email,
        'phone_number'          : phone.isNotEmpty ? phone : null,
        'password'              : password,
        'password_confirmation' : confirm,
      });

      if (!mounted) return;

      if (res['success'] == true) {
        _submittedEmail = email;
        setState(() => _view = 2); // show pending confirmation
      } else {
        _showError(_extractError(res));
      }
    } catch (_) {
      _showError('Connection error. Please check your network.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Log In submit ─────────────────────────────────────────────────────────

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.loginPatrol(
        email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/patrol-home');
    } else {
      _showError(result.message);
    }
  }

  // ── Check registration status ─────────────────────────────────────────────

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.post('patrol/registration-status',
          {'email': _submittedEmail});

      if (!mounted) return;
      final status = res['data']?['status'] as String? ?? 'pending';

      if (status == 'approved') {
        _showStatusDialog(
          icon:    Icons.check_circle,
          color:   Colors.green,
          title:   'Account Approved!',
          message: 'Your patrol account is ready. Please log in.',
          action:  () { Navigator.pop(context); setState(() => _view = 1); },
          actionLabel: 'Log In',
        );
      } else if (status == 'rejected') {
        final reason = res['data']?['rejection_reason'] as String?
                       ?? 'No reason provided.';
        _showStatusDialog(
          icon:    Icons.cancel,
          color:   Colors.red,
          title:   'Registration Not Approved',
          message: 'Reason: $reason\n\nContact your supervisor for assistance.',
          action:  () => Navigator.pop(context),
          actionLabel: 'OK',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Still pending review. Check back later.',
              style: TextStyle(fontFamily: 'Montserrat')),
          duration: Duration(seconds: 3),
        ));
      }
    } catch (_) {
      if (mounted) _showError('Could not check status. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showStatusDialog({
    required IconData icon,
    required Color    color,
    required String   title,
    required String   message,
    required VoidCallback action,
    required String   actionLabel,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 52),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat', fontSize: 13, color: Colors.black54,
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B78),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(actionLabel,
                style: const TextStyle(fontFamily: 'Montserrat')),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Montserrat')),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 3),
    ));
  }

  String _extractError(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) {
      final first = data.values.firstOrNull;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return res['message'] as String? ?? 'Something went wrong.';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _view == 2 ? _buildPending() : _buildForm(),
          ),
        ),
      ),
    );
  }

  // ── Pending confirmation view ─────────────────────────────────────────────

  Widget _buildPending() {
    return Column(
      key: const ValueKey('pending'),
      children: [
        const SizedBox(height: 20),
        Center(child: Image.asset('assets/logo/logo.png',
            height: 90, width: 90)),
        const SizedBox(height: 32),

        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: const Icon(Icons.hourglass_empty,
              color: Colors.orange, size: 40),
        ),

        const SizedBox(height: 20),

        const Text(
          'Registration Submitted!',
          style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 20,
            fontWeight: FontWeight.bold, color: Colors.black87,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Your registration request has been sent to the\nTOC Admin for verification.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 13,
            color: Colors.black54, height: 1.6,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'You will receive a notification once your\naccount has been approved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 13,
            color: Colors.black54, height: 1.6,
          ),
        ),

        const SizedBox(height: 32),

        // What happens next
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1A6B78).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('What happens next:',
                  style: TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.bold,
                    fontSize: 13, color: Color(0xFF1A6B78),
                  )),
              SizedBox(height: 8),
              _Step(number: '1', text: 'TOC Admin reviews your information'),
              SizedBox(height: 4),
              _Step(number: '2', text: 'Admin verifies you are a real officer'),
              SizedBox(height: 4),
              _Step(number: '3', text: 'You receive a push notification with the result'),
              SizedBox(height: 4),
              _Step(number: '4', text: 'Log in with your credentials once approved'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Check status
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _checkStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B78),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Check Status',
                    style: TextStyle(fontFamily: 'Montserrat',
                        fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 12),

        // Go to Log In
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() { _view = 1; }),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1A6B78)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Already approved? Log In',
                style: TextStyle(
                  fontFamily: 'Montserrat', fontSize: 14,
                  color: Color(0xFF1A6B78), fontWeight: FontWeight.w600,
                )),
          ),
        ),
      ],
    );
  }

  // ── Sign Up / Log In form view ────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        Center(child: Image.asset('assets/logo/logo.png',
            height: 90, width: 90)),

        const SizedBox(height: 20),

        Text(
          _view == 0 ? 'Create Account' : 'Patrol Sign In',
          style: const TextStyle(
            fontFamily: 'Montserrat', fontSize: 22,
            fontWeight: FontWeight.bold, color: Colors.black87,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          _view == 0
              ? 'Fill in your details. TOC Admin will verify your account.'
              : 'Use your administrator-approved credentials.',
          style: const TextStyle(
            fontFamily: 'Montserrat', fontSize: 13,
            fontWeight: FontWeight.bold, color: Colors.black87,
          ),
        ),

        const SizedBox(height: 20),

        RoleToggle(
          selectedIndex: 1,
          onChanged: (i) {
            if (i == 0) Navigator.pushReplacementNamed(context, '/register');
          },
        ),

        const SizedBox(height: 24),

        if (_view == 0) ..._buildSignUpFields()
        else            ..._buildLoginFields(),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : (_view == 0 ? _submitRegistration : _login),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF1A6B78),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    _view == 0 ? 'Submit Registration' : 'Sign In',
                    style: const TextStyle(fontFamily: 'Montserrat',
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _view = _view == 0 ? 1 : 0;
              _loginPasswordCtrl.clear();
            }),
            child: Text(
              _view == 0
                  ? 'Already have an account? Sign In'
                  : 'New registration? Sign Up',
              style: const TextStyle(
                fontFamily: 'Montserrat', fontSize: 13,
                color: Color(0xFF1A6B78),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildSignUpFields() => [
    Row(children: [
      Expanded(child: AppInputField(
          hint: 'First Name', controller: _firstNameCtrl,
          prefixIcon: FontAwesomeIcons.userGroup)),
      const SizedBox(width: 12),
      Expanded(child: AppInputField(
          hint: 'Last Name', controller: _lastNameCtrl,
          prefixIcon: FontAwesomeIcons.userGroup)),
    ]),
    const SizedBox(height: 12),
    AppInputField(
      hint: 'Email Address', controller: _emailCtrl,
      prefixIcon: FontAwesomeIcons.envelope,
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    AppInputField(
      hint: 'Contact Number', controller: _phoneCtrl,
      prefixIcon: FontAwesomeIcons.phone,
      keyboardType: TextInputType.phone,
    ),
    const SizedBox(height: 12),
    AppInputField(
      hint: 'Password', controller: _passwordCtrl,
      prefixIcon: FontAwesomeIcons.key,
      obscureText: !_pwVisible,
      suffixIcon: _pwVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
      onSuffixTap: () => setState(() => _pwVisible = !_pwVisible),
    ),
    const SizedBox(height: 12),
    AppInputField(
      hint: 'Repeat Password', controller: _confirmCtrl,
      prefixIcon: FontAwesomeIcons.key,
      obscureText: !_repeatVisible,
      suffixIcon: _repeatVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
      onSuffixTap: () => setState(() => _repeatVisible = !_repeatVisible),
    ),
  ];

  List<Widget> _buildLoginFields() => [
    AppInputField(
      hint: 'Email Address', controller: _emailCtrl,
      prefixIcon: FontAwesomeIcons.envelope,
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 12),
    AppInputField(
      hint: 'Password', controller: _loginPasswordCtrl,
      prefixIcon: FontAwesomeIcons.key,
      obscureText: !_pwVisible,
      suffixIcon: _pwVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
      onSuffixTap: () => setState(() => _pwVisible = !_pwVisible),
    ),
  ];
}

// ── Small helper widget ───────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 20, height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFF1A6B78), shape: BoxShape.circle),
        child: Center(
          child: Text(number,
              style: const TextStyle(
                fontFamily: 'Montserrat', color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold,
              )),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
              fontFamily: 'Montserrat', fontSize: 12, color: Colors.black87,
            )),
      ),
    ],
  );
}
