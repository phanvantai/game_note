import 'package:flutter/material.dart';

class EventsView extends StatefulWidget {
  const EventsView({Key? key}) : super(key: key);

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange[100],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            shape: Border.all(color: Colors.transparent),
            collapsedShape: Border.all(color: Colors.transparent),
            initiallyExpanded: true,
            // showTrailingIcon: false,
            title: const Text(
              'Sắp diễn ra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: const [
              Center(
                child: Text('Không có trận đấu nào sắp diễn ra'),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              color: Colors.cyan[50],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'Gần đây',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: 0,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text('Đội ${index + 1}'),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
