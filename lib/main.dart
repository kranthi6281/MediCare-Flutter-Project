
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color purple = Color(0xFF6254D9);
const Color teal = Color(0xFF19B6B0);
const Color navy = Color(0xFF29265B);
const Color pageBg = Color(0xFFF3F5FC);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediCareApp());
}

// =====================================================
// APP
// =====================================================

class MediCareApp extends StatelessWidget {
  const MediCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediCare',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          primary: purple,
          secondary: teal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBg,
          foregroundColor: navy,
          elevation: 0,
        ),
      ),
      home: const AppController(),
    );
  }
}

// =====================================================
// APP CONTROLLER AND LOCAL STORAGE
// =====================================================

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  bool loading = true;

  Map<String, dynamic>? currentUser;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsers = jsonDecode(prefs.getString('users') ?? '[]');
    final savedAppointments =
        jsonDecode(prefs.getString('appointments') ?? '[]');

    users = List<Map<String, dynamic>>.from(
      (savedUsers as List).map((e) => Map<String, dynamic>.from(e)),
    );

    appointments = List<Map<String, dynamic>>.from(
      (savedAppointments as List)
          .map((e) => Map<String, dynamic>.from(e)),
    );

    final savedEmail = prefs.getString('loggedInEmail');

    if (savedEmail != null) {
      for (final user in users) {
        if (user['email'] == savedEmail) {
          currentUser = user;
          break;
        }
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(users));
  }

  Future<void> saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appointments', jsonEncode(appointments));
  }

  Future<String?> register(
    String name,
    String email,
    String password,
  ) async {
    if (users.any((u) => u['email'] == email)) {
      return 'This email is already registered.';
    }

    users.add({
      'name': name,
      'email': email,
      'password': password,
    });

    await saveUsers();
    return null;
  }

  Future<String?> login(String email, String password) async {
    for (final user in users) {
      if (user['email'] == email && user['password'] == password) {
        currentUser = user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInEmail', email);

        if (mounted) setState(() {});
        return null;
      }
    }

    return 'Invalid email or password. Please register first.';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInEmail');

    if (mounted) {
      setState(() => currentUser = null);
    }
  }

  Future<void> addAppointment(
    Map<String, dynamic> appointment,
  ) async {
    appointment['email'] = currentUser!['email'];
    appointment['id'] = DateTime.now().microsecondsSinceEpoch.toString();

    appointments.add(appointment);
    await saveAppointments();

    if (mounted) setState(() {});
  }

  Future<void> cancelAppointment(String id) async {
    final index = appointments.indexWhere((a) => a['id'] == id);

    if (index != -1) {
      appointments[index]['status'] = 'Cancelled';
      await saveAppointments();

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: purple),
        ),
      );
    }

    if (currentUser == null) {
      return LoginScreen(
        onLogin: login,
        onRegister: register,
      );
    }

    return MainScreen(
      user: currentUser!,
      appointments: appointments
          .where((a) => a['email'] == currentUser!['email'])
          .toList(),
      onBook: addAppointment,
      onCancel: cancelAppointment,
      onLogout: logout,
    );
  }
}

// =====================================================
// DOCTOR MODEL AND DATA
// =====================================================

class Doctor {
  final String name;
  final String specialty;
  final String experience;
  final String fee;
  final IconData icon;
  final Color color;

  const Doctor({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.fee,
    required this.icon,
    required this.color,
  });
}

const List<Doctor> doctors = [
  Doctor(
    name: 'Dr. Kiran Rao',
    specialty: 'General Physician',
    experience: '8 years experience',
    fee: '500',
    icon: Icons.medical_services,
    color: Color(0xFF6254D9),
  ),
  Doctor(
    name: 'Dr. Ananya Sharma',
    specialty: 'Cardiologist',
    experience: '10 years experience',
    fee: '800',
    icon: Icons.favorite,
    color: Color(0xFFE85D75),
  ),
  Doctor(
    name: 'Dr. Rahul Verma',
    specialty: 'Dermatologist',
    experience: '7 years experience',
    fee: '600',
    icon: Icons.face,
    color: Color(0xFF9575CD),
  ),
  Doctor(
    name: 'Dr. Priya Reddy',
    specialty: 'Pediatrician',
    experience: '9 years experience',
    fee: '700',
    icon: Icons.child_care,
    color: Color(0xFFFFA726),
  ),
  Doctor(
    name: 'Dr. Arjun Kumar',
    specialty: 'Neurologist',
    experience: '12 years experience',
    fee: '900',
    icon: Icons.psychology,
    color: Color(0xFF26A69A),
  ),
];

// =====================================================
// REUSABLE GRADIENT BUTTON
// =====================================================

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [purple, teal],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

// =====================================================
// LOGIN SCREEN
// =====================================================

class LoginScreen extends StatefulWidget {
  final Future<String?> Function(String, String) onLogin;
  final Future<String?> Function(String, String, String) onRegister;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool hidePassword = true;
  bool busy = false;

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      message('Please enter email and password.');
      return;
    }

    setState(() => busy = true);

    final error = await widget.onLogin(
      email.text.trim().toLowerCase(),
      password.text,
    );

    if (!mounted) return;

    setState(() => busy = false);

    if (error != null) message(error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5142B8),
              Color(0xFF8276ED),
              Color(0xFF19B6B0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(
                    Icons.health_and_safety_rounded,
                    size: 82,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'MediCare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Your Health, Our Priority',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to continue to your account.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Email Address',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: purple,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F3FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: password,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: purple,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: purple,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F3FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          text: 'LOGIN',
                          loading: busy,
                          onPressed: signIn,
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text("Don't have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterScreen(
                                        onRegister: widget.onRegister,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Your health journey starts here.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// REGISTER SCREEN
// =====================================================

class RegisterScreen extends StatefulWidget {
  final Future<String?> Function(String, String, String) onRegister;

  const RegisterScreen({
    super.key,
    required this.onRegister,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool busy = false;

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget registerField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: purple),
          filled: true,
          fillColor: const Color(0xFFF4F3FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> createAccount() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty) {
      message('Please fill in all fields.');
      return;
    }

    if (!email.text.trim().contains('@')) {
      message('Please enter a valid email.');
      return;
    }

    if (password.text.length < 6) {
      message('Password must contain at least 6 characters.');
      return;
    }

    if (password.text != confirm.text) {
      message('Passwords do not match.');
      return;
    }

    setState(() => busy = true);

    final error = await widget.onRegister(
      name.text.trim(),
      email.text.trim().toLowerCase(),
      password.text,
    );

    if (!mounted) return;

    setState(() => busy = false);

    if (error != null) {
      message(error);
    } else {
      message('Account created successfully! Please login.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5142B8),
              Color(0xFF8276ED),
              Color(0xFF19B6B0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 65,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join MediCare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your details to get started.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 25),
                      registerField(
                        'Full Name',
                        Icons.person_outline,
                        name,
                      ),
                      registerField(
                        'Email Address',
                        Icons.email_outlined,
                        email,
                        keyboard: TextInputType.emailAddress,
                      ),
                      registerField(
                        'Password',
                        Icons.lock_outline,
                        password,
                        obscure: true,
                      ),
                      registerField(
                        'Confirm Password',
                        Icons.lock_reset,
                        confirm,
                        obscure: true,
                      ),
                      const SizedBox(height: 8),
                      GradientButton(
                        text: 'CREATE ACCOUNT',
                        loading: busy,
                        onPressed: createAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// =====================================================

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> appointments;
  final Future<void> Function(Map<String, dynamic>) onBook;
  final Future<void> Function(String) onCancel;
  final Future<void> Function() onLogout;

  const MainScreen({
    super.key,
    required this.user,
    required this.appointments,
    required this.onBook,
    required this.onCancel,
    required this.onLogout,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  void openBooking(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentScreen(
          doctor: doctor,
          user: widget.user,
          onBook: widget.onBook,
          onFinished: () {
            setState(() => selectedIndex = 2);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        user: widget.user,
        onBook: openBooking,
      ),
      DoctorsPage(onBook: openBooking),
      BookingsPage(
        appointments: widget.appointments,
        onCancel: widget.onCancel,
      ),
      ProfilePage(
        user: widget.user,
        onLogout: widget.onLogout,
        onBookings: () => setState(() => selectedIndex = 2),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE7E3FF),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: purple),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services, color: purple),
            label: 'Doctors',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: purple),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: purple),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HOME PAGE
// =====================================================

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;
  final Function(Doctor) onBook;

  const HomePage({
    super.key,
    required this.user,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE7E3FF),
              child: Icon(Icons.health_and_safety, color: purple),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'MediCare',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: purple),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text(
          'Hello, ${user['name']}!',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'How are you feeling today?',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 23),
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [purple, Color(0xFF8276ED), teal],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 38,
              ),
              const SizedBox(height: 13),
              const Text(
                'Your Health,\nOur Priority',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Connect with trusted doctors and book your appointment easily.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => onBook(doctors[0]),
                icon: const Icon(Icons.calendar_month),
                label: const Text('BOOK NOW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,   

                    
                    vertical: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        const SectionTitle(title: 'Our Specialties'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: doctors.map((doctor) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 52) / 2,
              child: SpecialtyCard(
                doctor: doctor,
                onTap: () => onBook(doctor),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 27),
        const SectionTitle(title: 'Available Doctors'),
        const SizedBox(height: 13),
        ...doctors.take(3).map(
          (doctor) => DoctorCard(
            doctor: doctor,
            onTap: () => onBook(doctor),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// DOCTORS PAGE
// =====================================================

class DoctorsPage extends StatefulWidget {
  final Function(Doctor) onBook;

  const DoctorsPage({super.key, required this.onBook});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = doctors.where((d) {
      return d.name.toLowerCase().contains(search.toLowerCase()) ||
          d.specialty.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Find Your Doctor',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: InputDecoration(
              hintText: 'Search doctor or specialty',
              prefixIcon: const Icon(Icons.search, color: purple),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No doctors found.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: filtered.map((doctor) {
                    return DoctorCard(
                      doctor: doctor,
                      onTap: () => widget.onBook(doctor),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// =====================================================
// APPOINTMENT BOOKING PAGE
// =====================================================

class AppointmentScreen extends StatefulWidget {
  final Doctor doctor;
  final Map<String, dynamic> user;
  final Future<void> Function(Map<String, dynamic>) onBook;
  final VoidCallback onFinished;

  const AppointmentScreen({
    super.key,
    required this.doctor,
    required this.user,
    required this.onBook,
    required this.onFinished,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final patientName = TextEditingController();
  final phone = TextEditingController();
  final reason = TextEditingController();

  DateTime? selectedDate;
  String selectedTime = '10:00 AM';
  bool busy = false;

  final slots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    patientName.text = widget.user['name'] ?? '';
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> bookAppointment() async {
    if (patientName.text.trim().isEmpty ||
        phone.text.trim().length != 10 ||
        reason.text.trim().isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields correctly.'),
        ),
      );
      return;
    }

    setState(() => busy = true);

    await widget.onBook({
      'doctorName': widget.doctor.name,
      'specialty': widget.doctor.specialty,
      'fee': widget.doctor.fee,
      'patientName': patientName.text.trim(),
      'phone': phone.text.trim(),
      'reason': reason.text.trim(),
      'date': selectedDate!.toIso8601String(),
      'time': selectedTime,
      'status': 'Booked',
    });

    if (!mounted) return;

    setState(() => busy = false);

    widget.onFinished();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment booked successfully!'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DoctorCard(
            doctor: widget.doctor,
            onTap: () {},
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Patient Information'),
          const SizedBox(height: 15),
          TextField(
            controller: patientName,
            decoration: const InputDecoration(
              labelText: 'Patient Name',
              prefixIcon: Icon(Icons.person, color: purple),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone, color: purple),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: reason,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for Visit',
              prefixIcon: Icon(Icons.notes, color: purple),
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 23),
          const SectionTitle(title: 'Select Appointment Date'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: chooseDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              selectedDate == null
                  ? 'Choose Date'
                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
            ),
          ),
          const SizedBox(height: 23),
          const SectionTitle(title: 'Available Time Slots'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              return ChoiceChip(
                label: Text(slot),
                selected: selectedTime == slot,
                selectedColor: const Color(0xFFE4E0FF),
                onSelected: (_) {
                  setState(() => selectedTime = slot);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 23),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E3FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Consultation Fee',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${widget.doctor.fee}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            text: 'CONFIRM APPOINTMENT',
            loading: busy,
            onPressed: bookAppointment,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// MY APPOINTMENTS PAGE
// =====================================================

class BookingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final Future<void> Function(String) onCancel;

  const BookingsPage({
    super.key,
    required this.appointments,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...appointments]
      ..sort((a, b) => b['id'].compareTo(a['id']));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'My Appointments',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 75,
                        color: Color(0xFFB9B5D9),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No appointments yet',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      Text('Your bookings will appear here.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final a = sorted[index];
                    final date = DateTime.parse(a['date']);
                    final cancelled = a['status'] == 'Cancelled';

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFE7E3FF),
                                  child: Icon(
                                    Icons.medical_services,
                                    color: purple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a['doctorName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: navy,
                                        ),
                                      ),
                                      Text(a['specialty']),
                                    ],
                                  ),
                                ),
                                Text(
                                  cancelled ? 'Cancelled' : 'Booked',
                                  style: TextStyle(
                                    color: cancelled
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 25),
                            detailRow(Icons.person, a['patientName']),
                            detailRow(
                              Icons.calendar_today,
                              '${date.day}/${date.month}/${date.year}',
                            ),
                            detailRow(Icons.access_time, a['time']),
                            detailRow(Icons.phone, a['phone']),
                            detailRow(
                              Icons.currency_rupee,
                              a['fee'],
                            ),
                            if (!cancelled)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await onCancel(a['id']);
                                  },
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Cancel Appointment',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// =====================================================
// PROFILE PAGE
// =====================================================

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  final VoidCallback onBookings;

  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onBookings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 30),
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFFE7E3FF),
          child: Icon(Icons.person, size: 60, color: purple),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            user['name'],
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ),
        Center(
          child: Text(
            user['email'],
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 30),
        profileTile(
          Icons.person_outline,
          'Full Name',
          user['name'],
        ),
        profileTile(
          Icons.email_outlined,
          'Email Address',
          user['email'],
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(
              Icons.calendar_month,
              color: purple,
            ),
            title: const Text('My Appointments'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onBookings,
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () async {
              await onLogout();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'LOGOUT',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// REUSABLE WIDGETS
// =====================================================

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    );
  }
}

class SpecialtyCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const SpecialtyCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: doctor.color.withOpacity(0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: doctor.color.withOpacity(0.13),
              child: Icon(
                doctor.icon,
                color: doctor.color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              doctor.specialty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: doctor.color.withOpacity(0.13),
              child: Icon(
                doctor.icon,
                color: doctor.color,
                size: 30,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(doctor.specialty),
                  Text(
                    doctor.experience,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Consultation: ₹${doctor.fee}',
                    style: TextStyle(
                      color: doctor.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: purple,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget detailRow(IconData icon, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 19, color: purple),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

Widget profileTile(IconData icon, String title, String value) {
  return Card(
    color: Colors.white,
    child: ListTile(
      leading: Icon(icon, color: purple),
      title: Text(title),
      subtitle: Text(value),
    ),
  );
}
