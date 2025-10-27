ExpansionTile(
  leading: const Icon(Icons.extension),
  title: const Text('Add-ons'),
  children: [
    ListTile(
      leading: const Icon(Icons.add_circle_outline),
      title: const Text('Create Auction'),
      onTap: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => const CreateAuctionDialog(),
        );
      },
    ),
    ListTile(
      leading: const Icon(Icons.analytics_outlined),
      title: const Text('View Analytics'),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedIndex = 0; // Go to analytics screen
        });
      },
    ),
  ],
),
