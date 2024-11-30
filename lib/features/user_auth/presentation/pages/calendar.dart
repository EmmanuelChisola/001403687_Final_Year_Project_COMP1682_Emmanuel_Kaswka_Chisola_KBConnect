import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/event.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late Map<DateTime, List<Event>> selectedEvents;
  CalendarFormat format = CalendarFormat.month;
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  bool isAdmin = false;

  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  String? _selectedEventId;

  @override
  void initState() {
    selectedEvents = {};
    _fetchEventsFromFirestore();
    _checkAdminStatus();
    _deletePastEvents();
    super.initState();
  }
  void _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email == 'testuser@gmail.com') {
      setState(() {
        isAdmin = true;
      });
    }
  }

  Future<void> _addEventToFirestore(Event event) async {
    try {
      await FirebaseFirestore.instance.collection('events').add({
        'date': selectedDay,
        'title': event.title,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Event added successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred while adding an event."),
        ),
      );
    }
  }

  Future<void> _updateEventInFirestore(String id, String title) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(id).update({
        'title': title,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Event updated successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred while updating an event."),
        ),
      );
    }
  }

  Future<void> _deleteEventFromFirestore(String id) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Event deleted successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred while deleting event."),
        ),
      );
    }
  }

  // Function to delete past events from Firestore
  Future<void> _deletePastEvents() async {
    DateTime now = DateTime.now();
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('date', isLessThan: now)
          .get();

      for (var doc in snapshot.docs) {
        await FirebaseFirestore.instance.collection('events').doc(doc.id).delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred while deleting past events."),
        ),
      );
    }
  }

  Future<void> _fetchEventsFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('events').get();
      selectedEvents = {}; // Reset events to avoid duplication

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime eventDate = (data['date'] as Timestamp).toDate();
        String title = data['title'];
        String id = doc.id; // Get the document ID

        DateTime eventDateWithoutTime = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (selectedEvents[eventDateWithoutTime] != null) {
          selectedEvents[eventDateWithoutTime]?.add(Event(title: title, id: id));
        } else {
          selectedEvents[eventDateWithoutTime] = [Event(title: title, id: id)];
        }
      }
      setState(() {
        _fetchEventsFromFirestore();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred while fetching events."),
        ),
      );
    }
  }

  List<Event> _getEventsfromDay(DateTime date) {
    DateTime dateWithoutTime = DateTime(date.year, date.month, date.day);
    return selectedEvents[dateWithoutTime] ?? [];
  }

  @override
  void dispose() {
    _eventController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _showEditDialog(Event event) {
    _editController.text = event.title;
    _selectedEventId = event.id; // Set the selected event ID

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Event"),
        content: TextFormField(
          controller: _editController,
          decoration: InputDecoration(
            hintText: "Enter new event title",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text("Update"),
            onPressed: () {
              if (_editController.text.isNotEmpty && _selectedEventId != null) {
                _updateEventInFirestore(_selectedEventId!, _editController.text);
                setState(() {
                  selectedEvents[selectedDay]?.firstWhere((e) => e.id == _selectedEventId)?.title = _editController.text;
                });
                Navigator.pop(context);
                _editController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text("Yes"),
            onPressed: () {
              if (eventId.isNotEmpty) {
                _deleteEventFromFirestore(eventId);
                setState(() {
                  selectedEvents[selectedDay]?.removeWhere((e) => e.id == eventId);
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Event> eventsForSelectedDay = _getEventsfromDay(selectedDay);

    bool isPastDate(DateTime date) {
      return date.isBefore(DateTime.now());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TableCalendar(
                focusedDay: focusedDay,
                firstDay: DateTime(1990),
                lastDay: DateTime(2090),
                calendarFormat: format,
                onFormatChanged: (CalendarFormat _format) {
                  setState(() {
                    format = _format;
                  });
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                daysOfWeekVisible: true,
                onDaySelected: (DateTime selectDay, DateTime focusDay) {
                  setState(() {
                    selectedDay = DateTime(selectDay.year, selectDay.month, selectDay.day);
                    focusedDay = focusDay;
                  });
                },
                selectedDayPredicate: (DateTime date) {
                  return isSameDay(selectedDay, date);
                },
                eventLoader: _getEventsfromDay,
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  selectedDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Colors.amberAccent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  weekendDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: eventsForSelectedDay.isEmpty
                ? const Center(
              child: Text(
                'No scheduled events today.',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            )
                : ListView.builder(
              itemCount: eventsForSelectedDay.length,
              itemBuilder: (context, index) {
                Event event = eventsForSelectedDay[index];
                DateTime? eventDate;

                selectedEvents.forEach((date, events) {
                  if (events.contains(event)) {
                    eventDate = date;
                  }
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.blueAccent),
                      title: Center(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Center(
                        child: Text(
                          "Date: ${eventDate != null ? "${eventDate!.day}-${eventDate!.month}-${eventDate!.year}" : ""}",
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      trailing: isAdmin ?
                      Row (
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton (
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () => _showEditDialog(event),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _showDeleteDialog(event.id),
                          ),
                        ],
                      )
                      :null ,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        backgroundColor: isPastDate(selectedDay) ? Colors.grey : Colors.blueAccent,
        onPressed: () {
          if (isPastDate(selectedDay)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot add events on past dates."),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Add Event"),
                content: TextFormField(
                  controller: _eventController,
                  decoration: InputDecoration(
                    hintText: "Enter event title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text("Add"),
                    onPressed: () {
                      if (_eventController.text.isNotEmpty) {
                        Event newEvent = Event(title: _eventController.text, id: ""); // id will be set when fetched from Firestore
                        setState(() {
                          if (selectedEvents[selectedDay] != null) {
                            selectedEvents[selectedDay]?.add(newEvent);
                          } else {
                            selectedEvents[selectedDay] = [newEvent];
                          }
                        });
                        _addEventToFirestore(newEvent);
                        Navigator.pop(context);
                        _eventController.clear();
                      }
                    },
                  ),
                ],
              ),
            );
          }
        },
        label: const Text(""),
        icon: const Icon(Icons.add,color: Colors.brown,),
      )
          : const SizedBox.shrink(),
    );
  }
}
