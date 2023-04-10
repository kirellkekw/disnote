import 'package:flutter/material.dart';
import 'package:disnote/assets/circular_box.dart';
import 'package:disnote/other/constants.dart';
import 'package:disnote/services/sql_helper.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<MainPage> {
  // All journals

  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item

  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _contentController.text = existingJournal['content'];
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          color: kBackgroundColor,
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                height: 30,
              ),
              TextField(
                style: const TextStyle(
                  color: kIconColor,
                  fontSize: 17,
                ),
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: kIconColor,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                minLines: 1,
                maxLines: 9,
                style: const TextStyle(
                  color: kIconColor,
                  fontSize: 17,
                ),
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Content',
                  hintStyle: TextStyle(
                    color: kIconColor,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(kBoxColor),
                ),
                onPressed: () async {
                  // Save new journal
                  if (id == null) {
                    await _createItem();
                  }
                  if (id != null) {
                    await _updateItem(id);
                  }
                  // Clear the text fields
                  _titleController.text = '';
                  _contentController.text = '';
                  // Close the bottom sheet
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(
                  id == null ? 'Create New' : 'Update',
                  style: const TextStyle(
                    color: kTextColor,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

// Insert a new journal to the database
  Future<void> _createItem() async {
    await SQLHelper.createItem(_titleController.text, _contentController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _contentController.text);
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Disnote',
            style: TextStyle(
              color: kTextColor,
            ),
          ),
        ),
        backgroundColor: kBackgroundColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: _journals.length,
              itemBuilder: (_, index) {
                return CircularBox(
                  color: kBoxColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _journals[index]['title'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          _journals[index]['content'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: const Icon(
                              Icons.edit,
                              color: kIconColor,
                            ),
                            onPressed: () {
                              _showForm(
                                _journals[index]['id'],
                              );
                            },
                          ),
                          IconButton(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: const Icon(
                              Icons.delete,
                              color: kIconColor,
                            ),
                            onPressed: () {
                              _deleteItem(_journals[index]['id']);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kIconColor,
        onPressed: () {
          _showForm(null);
        },
        child: const Icon(
          Icons.add,
          color: kBackgroundColor,
        ),
      ),
    );
  }
}
