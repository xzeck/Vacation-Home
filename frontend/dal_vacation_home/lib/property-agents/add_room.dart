import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/commands/rooms_commands.dart';
import 'package:dal_vacation_home/commands/upload_file_to_s3.dart';
import 'package:dal_vacation_home/models/room.dart';
import 'package:dal_vacation_home/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddRoom extends StatefulWidget {
  const AddRoom(
      {super.key, required this.rooms, this.room, this.isEdit = false});
  final List<Room> rooms;
  final Room? room;
  final bool isEdit;

  @override
  State<AddRoom> createState() => _AddRoomState();
}

class _AddRoomState extends State<AddRoom> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomPriceController = TextEditingController();
  final TextEditingController _facilityController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  String imageUrl = '';
  RoomType? _roomType;
  bool isUploading = false;
  bool isAddingRoom = false;
  List<Room> _rooms = [];
  List<String> _facilities = [];
  Room? roomToEdit;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    _rooms = widget.rooms;
    roomToEdit = widget.room;
    isEdit = widget.isEdit;
    if (isEdit) {
      _roomNameController.text = roomToEdit?.roomId.toString() ?? '';
      _roomPriceController.text = roomToEdit?.price.toString() ?? '';
      imageUrl = roomToEdit?.image ?? '';
      _roomType = roomToEdit?.roomType ?? RoomType.small;
      // Initialize facilities if editing
      _facilities = roomToEdit?.facilities ?? [];
      // Initialize discount if editing
      _discountController.text = roomToEdit?.discount.toString() ?? '';
    }
  }

  bool _validate() {
    return _roomNameController.text.isNotEmpty &&
        _roomPriceController.text.isNotEmpty &&
        imageUrl.isNotEmpty &&
        _roomType != null &&
        _facilities.isNotEmpty;
  }

  Future<void> _addRoom(BuildContext ctx) async {
    isAddingRoom = true;
    setState(() {});
    if (!isEdit &&
        _rooms.any((Room room) =>
            room.roomId == int.parse(_roomNameController.text))) {
      showInSnackBar('Room with the same number already exists', ctx,
          isError: true);
      isAddingRoom = false;
      setState(() {});
      return;
    }
    final Room newRoom = Room(
      roomId: int.parse(_roomNameController.text),
      roomType: _roomType!,
      price: int.parse(_roomPriceController.text),
      bookedDates: [],
      image: imageUrl,
      facilities: _facilities,
      discount: int.parse(_discountController.text),
    );

    await Rooms.addRoom(context, newRoom);
    isAddingRoom = false;
    setState(() {});
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            enabled: !isEdit,
            controller: _roomNameController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Room Number',
            ),
          ),
          const SizedBox(height: 20),
          FormField(
            builder: (ctx) => InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Room Type',
              ),
              child: DropdownButtonHideUnderline(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                  child: DropdownButton(
                    focusColor: Colors.transparent,
                    isDense: true,
                    value: _roomType,
                    hint: const Text('Select Room Type'),
                    items: List.generate(
                      RoomType.values.length,
                      (index) => DropdownMenuItem(
                        value: RoomType.values[index],
                        child: Text(StringUtils.capitalize(
                            RoomType.values[index].name)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _roomType = value as RoomType;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _roomPriceController,
            decoration: const InputDecoration(
              prefix: Text('\$'),
              border: OutlineInputBorder(),
              labelText: 'Room Price',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _discountController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Discount',
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _facilityController,
            onSubmitted: (_) {
              if (_facilityController.text.isNotEmpty) {
                setState(() {
                  _facilities.add(_facilityController.text);
                  _facilityController.clear();
                });
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Add Facility',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_facilityController.text.isNotEmpty) {
                    setState(() {
                      _facilities.add(_facilityController.text);
                      _facilityController.clear();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _facilities.map((facility) {
              return Chip(
                label: Text(facility),
                onDeleted: () {
                  setState(() {
                    _facilities.remove(facility);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (imageUrl.isNotEmpty)
            SizedBox(
              height: 150,
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(imageUrl),
              ),
            ),
          ElevatedButton(
            onPressed: isUploading
                ? null
                : () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                    if (result != null) {
                      try {
                        isUploading = true;
                        setState(() {});
                        String? url = await uploadImageToS3(
                            result.files.single.bytes!,
                            result.files.single.name);
                        if (url != null) {
                          imageUrl = url;
                          setState(() {});
                        }
                      } on Exception catch (e) {
                        print(e.toString());
                      }
                    }
                    isUploading = false;
                    setState(() {});
                  },
            child: Text(isUploading
                ? 'Uploading...'
                : imageUrl.isEmpty
                    ? 'Upload Image'
                    : 'Change Image'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: !isAddingRoom && _validate()
                ? () {
                    _addRoom(context);
                  }
                : null,
            child: Text(isAddingRoom
                ? 'Loading...'
                : isEdit
                    ? 'Update Room'
                    : 'Add Room'),
          )
        ],
      ),
    );
  }
}
