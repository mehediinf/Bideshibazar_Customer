import 'package:flutter/material.dart';
import 'team_member.dart';

class TeamTab extends StatefulWidget {
  const TeamTab({Key? key}) : super(key: key);

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  late List<TeamMember> _teamMembers;

  @override
  void initState() {
    super.initState();
    _teamMembers = _getTeamMembers();
  }

  List<TeamMember> _getTeamMembers() {
    return [
      TeamMember(
        name: "Mst Munni Akter",
        title: "Founder",
        description: "Mst. Munni Akter is a passionate entrepreneur and founder of Bideshi Bazar, an innovative e-commerce platform based in Austria. "
            "With a strong vision to serve the Bangladeshi and South Asian community in Europe, she has played a key role in building the foundation of the company "
            "and obtaining the official EU e-commerce business license.\n\n"
            "Her dedication, leadership, and community-oriented mindset make her an inspiring figure behind the success of Bideshi Bazar. "
            "Munni Akter is committed to empowering people abroad with easier access to groceries, fashion, and essential services that help them stay connected to their roots while living in Europe.",
        imageAsset: "assets/images/woman.png",
      ),
      TeamMember(
        name: "Mahadi Hassan Shova",
        title: "Co-Founder and CEO",
        description: "Mahadi Hassan Shova is the visionary Co-Founder and CEO of Bideshi Bazar and the creative mind behind this app. "
            "Originally from Bangladesh and currently based in Vienna, Austria, Shova is pursuing his Master's in Computer Science at the University of Vienna. "
            "With a strong background in technology, e-commerce, and digital innovation, he aims to build platforms that make life easier for the Bangladeshi and broader South Asian community living abroad.\n\n"
            "Passionate about problem-solving, Shova combines his academic expertise with real-world business experience to create practical solutions that connect people, services, and cultures. "
            "This app is one of his initiatives to deliver smarter, faster, and user-friendly experiences for customers around the world.",
        imageAsset: "assets/images/boss1.jpg",
      ),
      TeamMember(
        name: "Avijit Ghosh",
        title: "Head of IT Development",
        description: "Avijit Ghosh is a passionate and skilled IT professional leading the development initiatives at Bideshibazar. "
            "With strong expertise in PHP, Laravel, MySQL, HTML, CSS, JavaScript, Ajax, Bootstrap, and modern web design, he plays a key role in building and optimizing digital solutions that power the Bideshibazar ecosystem.\n\n"
            "He is also pursuing his B.Sc. in Computer Science and Engineering (CSE) at Uttara University, continuously enhancing his technical and leadership abilities to drive innovation within the platform.",
        imageAsset: "assets/images/avijit.jpeg",
      ),
      TeamMember(
        name: "Md. Mehedi Hasan",
        title: "Head of Mobile Application Development",
        description: "Md. Mehedi Hasan leads the Mobile Application Development division at Bideshibazar, driving innovation and excellence in mobile technology. "
            "He specializes in building high-performance, user-friendly applications using Android (Java) and Flutter (Dart) frameworks.\n\n"
            "With deep expertise in Firebase, SQLite, and REST API integration, Mehedi focuses on delivering seamless and responsive user experiences. "
            "His work includes implementing advanced features like Google Sign-In, Apple Sign-In, Push Notifications, and Google Maps integration — ensuring Bideshibazar apps remain dynamic, reliable, and user-centric.\n\n"
            "Continuously exploring new technologies, he is committed to enhancing Bideshibazar's mobile platforms and shaping the future of digital commerce through innovation and technical excellence.",
        imageAsset: "assets/images/mehedi_hasan.jpg",
      ),
      TeamMember(
        name: "Biplob Chandra Shil",
        title: "Head of UI/UX Design",
        description: "Biplob Chandra Shil is a passionate and creative Graphic Designer at Bideshibazar, specializing in branding, logo design, "
            "and marketing materials that visually represent the brand's identity and values.\n\n"
            "With strong expertise in creative design, video editing, and digital marketing, Biplob blends artistic vision with modern marketing strategies to deliver visually captivating and results-driven content. "
            "His work focuses on crafting high-quality, engaging visuals that connect with audiences and help Bideshibazar strengthen its digital presence and brand growth.",
        imageAsset: "assets/images/biplop.jpeg",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamMembers.length + 1, // +1 for footer
      itemBuilder: (context, index) {
        if (index == _teamMembers.length) {
          // Footer - Need Help section
          return _buildFooter(context);
        }

        final member = _teamMembers[index];
        return _buildTeamMemberCard(member, index);
      },
    );
  }

  Widget _buildTeamMemberCard(TeamMember member, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          member.isExpanded = !member.isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: member.isExpanded
            ? _buildExpandedCard(member)
            : _buildCollapsedCard(member),
      ),
    );
  }

  Widget _buildCollapsedCard(TeamMember member) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                member.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 32, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Expand icon
          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(TeamMember member) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with profile image
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0071CE), width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    member.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            member.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '11 more developers work in our company',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton({
    IconData? icon,
    String? imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image, color: const Color(0xFF9B4DFF), size: 20);
                  },
                )
              else if (icon != null)
                Icon(icon, color: const Color(0xFF9B4DFF), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9B4DFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}