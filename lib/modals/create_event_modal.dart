import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/ministry.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class CreateEventModal extends StatefulWidget {
  final Ministry ministry;

  const CreateEventModal({
    super.key,
    required this.ministry,
  });

  @override
  State<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<CreateEventModal> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? imageFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create New Event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : DateFormat('MMM d, y').format(selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365),
                    ),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                title: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : selectedTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(
                  imageFile == null
                      ? 'Select Event Image'
                      : 'Image Selected',
                ),
                trailing: imageFile != null
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        selectedDate != null &&
                        selectedTime != null &&
                        imageFile != null) {
                      try {
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('ministry_events')
                            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

                        await storageRef.putFile(imageFile!);
                        final imageUrl = await storageRef.getDownloadURL();

                        final date = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );

                        await FirebaseFirestore.instance
                            .collection('ministry_events')
                            .add({
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'date': date,
                              'imageUrl': imageUrl,
                              'ministryId': FirebaseFirestore.instance
                                  .collection('ministries')
                                  .doc(widget.ministry.id),
                              'attendees': [],
                              'isActive': true,
                              'createdAt': FieldValue.serverTimestamp(),
                              'createdBy': FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(Provider.of<AuthService>(context, listen: false).currentUser?.uid),
                            });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event created successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating event: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Create Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 