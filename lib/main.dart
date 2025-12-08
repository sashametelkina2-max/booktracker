import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:toastification/toastification.dart';

enum BookState {
  New, // новая
  Reading, // в процессе чтения
  Abandoned, // заброшена
}

enum Page { Home, BookCreate, BookEdit, CurrentPageEdit, SetupDayGoal }

int getValuePercentage(int value, int all) {
  if (value == 0) return 0;
  return (min(value, all) / all * 100.0).round();
}

int now() {
  return DateTime.now().millisecondsSinceEpoch;
}

bool isToday(int timestamp) {
  // Преобразуем timestamp (в миллисекундах) в DateTime
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

  // Получаем текущую дату
  final now = DateTime.now();

  // Сравниваем только год, месяц и день
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

class Book {
  int id = 0;
  String title;
  String author;
  int pages;
  int currentPage;
  BookState state;
  String? imagePath;

  int? rate;
  String notes = "";

  Book({
    required this.title,
    required this.author,
    required this.pages,
    this.rate,
    this.imagePath,
    this.notes = "",
    this.currentPage = 0,
    this.state = BookState.New,
    int? id,
  }) {
    this.id = id ?? now();
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      pages: json['pages'],
      currentPage: json['currentPage'],
      state: BookState.values.firstWhere((e) => e.toString() == json['state']),
      rate: json['rate'],
      notes: json['notes'],
      imagePath: json['imagePath'],
    );
  }

  Future<File?> getImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/$imagePath');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  int getPercentage() {
    return getValuePercentage(currentPage, pages);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'pages': pages,
      'currentPage': currentPage,
      'state': state.toString(),
      'rate': rate,
      'notes': notes,
      'imagePath': imagePath,
    };
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Book tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const MyHomePage(title: 'Book tracker'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Page page = Page.Home;
  int? currentBookIndex; // nullable, null safety
  List<Book> books = [];
  int dayPagesGoal = 10;
  int currentDayPages = 0;

  _MyHomePageState() {
    readData();
  }

  Future<void> saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    var books = this.books.map((item) => item.toJson()).toList();
    String jsonList = jsonEncode(books);
    await prefs.setString('books', jsonList);
    await prefs.setInt('pagesGoal', dayPagesGoal);
    await prefs.setInt('currentPages', currentDayPages);
    await prefs.setInt('currentTimestamp', now());
  }

  Future<void> readData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String booksString = prefs.getString('books') ?? "[]";
    final List<dynamic> jsonList = jsonDecode(booksString);
    setState(() {
      books = jsonList.map((jsonItem) => Book.fromJson(jsonItem)).toList();

      dayPagesGoal = prefs.getInt('pagesGoal') ?? 10;
      int? currentTimestamp = prefs.getInt('currentTimestamp');
      if (currentTimestamp != null) {
        int currentPages = prefs.getInt('currentPages') ?? 0;
        if (isToday(currentTimestamp)) {
          currentDayPages = currentPages;
        } else {
          currentDayPages = 0;
        }
      }
    });
  }

  void addBook(Book book, {bool redirect = true}) {
    setState(() {
      books.add(book);
      saveData();
      if (redirect) {
        page = Page.Home;
      }
    });
  }

  void saveBook(Book book, {bool redirect = true}) {
    setState(() {
      int index = books.indexWhere((b) => b.id == book.id);
      if (index == -1) return;
      books[index] = book;
      saveData();
      if (redirect) {
        page = Page.Home;
      }
    });
  }

  void deleteBook(Book book) {
    setState(() {
      int index = books.indexWhere((b) => b.id == book.id);
      if (index == -1) return;
      books.removeAt(index);
      saveData();
      page = Page.Home;
    });
  }

  void goHome() {
    setState(() {
      page = Page.Home;
    });
  }

  void createBook() {
    setState(() {
      page = Page.BookCreate;
    });
  }

  void editBook(int bookId) {
    setState(() {
      page = Page.BookEdit;
      currentBookIndex = bookId;
    });
  }

  void setCurrentBookPage(int bookId) {
    setState(() {
      page = Page.CurrentPageEdit;
      currentBookIndex = bookId;
    });
  }

  void setDayGoal() {
    setState(() {
      page = Page.SetupDayGoal;
    });
  }

  int getDayPercent() {
    return getValuePercentage(currentDayPages, dayPagesGoal);
  }

  Widget dayGoalButton() {
    int percent = getDayPercent();
    return ElevatedButton(
      onPressed: setDayGoal,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        // Set the background color here
        foregroundColor: Colors.white, // Set the text color here (optional)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                    backgroundColor: Colors.blue,
                    value: percent * 0.01,
                  ),
                ),
                Text("$percent%"),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text("Цель чтения на сегодня"),
                Text("Прочитано $currentDayPages/$dayPagesGoal страниц"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void goRead(Book book) {
    int index = books.indexWhere((book) => book.state == BookState.Reading);
    if (index != -1) {
      books[index].state = BookState.New;
    }
    book.state = BookState.Reading;
    saveBook(book, redirect: false);
  }

  void banBook(Book book) {
    book.state = BookState.Abandoned;
    saveBook(book);
  }

  Widget home() {
    return Column(
      children: [
        dayGoalButton(),
        BooksGroup(
          books:
              books.where((book) => book.state == BookState.Reading).toList(),
          title: "Читаю",
          elementInfo: true,
          setPageCallback: (book) => setCurrentBookPage(book.id),
          editCallback: (book) => editBook(book.id),
          goReadCallback: goRead,
          banCallback: banBook,
        ),
        BooksGroup(
          books: books.where((book) => book.state == BookState.New).toList(),
          title: "В процессе чтения",
          elementInfo: false,
          setPageCallback: (book) => setCurrentBookPage(book.id),
          editCallback: (book) => editBook(book.id),
          goReadCallback: goRead,
          banCallback: banBook,
        ),
        BooksGroup(
          books:
              books.where((book) => book.state == BookState.Abandoned).toList(),
          title: "Заброшенные",
          elementInfo: false,
          setPageCallback: (book) => setCurrentBookPage(book.id),
          editCallback: (book) => editBook(book.id),
          goReadCallback: goRead,
          banCallback: banBook,
        ),
      ],
    );
  }

  Widget bookEdit(Book book) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: goHome,
                child: Row(children: [Icon(Icons.arrow_back), Text("Назад")]),
              ),
            ),
            TextButton(
              onPressed: () => deleteBook(book),
              child: Row(children: [Icon(Icons.delete)]),
            ),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: LogoPicker(
            book: book,
            pick: (String path) => book.imagePath = path,
          ),
        ),
        inputField(
          defaultValue: book.title,
          label: "Название книги",
          placeholder: "Введите название книги",
          onChange: (value) => book.title = value,
        ),
        inputField(
          defaultValue: book.author,
          label: "Автор",
          placeholder: "Введите автора",
          onChange: (value) => book.author = value,
        ),
        inputField(
          defaultValue: book.pages.toString(),
          label: "Количество страниц",
          placeholder: "Введите количество страниц",
          onChange: (value) => book.pages = int.parse(value),
        ),
        inputField(
          defaultValue: book.notes.toString(),
          label: "Заметки",
          placeholder: "Вы можете здесь написать впечатления от книги",
          onChange: (value) => book.notes = value,
          maxLines: 5,
        ),
        SizedBox(height: 10),
        InputRate(
          rate: book.rate,
          label: "Оцените книгу",
          onChange: (value) => book.rate = value,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => saveBook(book),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                // Set the background color here
                foregroundColor:
                    Colors.white, // Set the text color here (optional)
              ),
              child: Text("Сохранить"),
            ),
          ],
        ),
      ],
    );
  }

  Widget setupDayGoal() {
    return Column(
      children: [
        TextButton(
          onPressed: goHome,
          child: Row(children: [Icon(Icons.arrow_back), Text("Назад")]),
        ),
        inputField(
          defaultValue: dayPagesGoal.toString(),
          label: "Цель чтения на день",
          placeholder: "Введите количество страниц",
          onChange: (value) => dayPagesGoal = int.parse(value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => page = Page.Home),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                // Set the background color here
                foregroundColor:
                    Colors.white, // Set the text color here (optional)
              ),
              child: Text("Сохранить"),
            ),
          ],
        ),
      ],
    );
  }

  Widget getCurrentPage() {
    if (page == Page.Home) {
      return home();
    } else if (page == Page.BookEdit) {
      return bookEdit(books.firstWhere((book) => book.id == currentBookIndex));
    } else if (page == Page.CurrentPageEdit) {
      return CurrentPageSet(
        book: books.firstWhere((book) => book.id == currentBookIndex),
        goHome: goHome,
        update: (int page) {
          int lastPercent = getDayPercent();
          var book = books.firstWhere((book) => book.id == currentBookIndex);
          int delta = page - book.currentPage;
          currentDayPages += delta;
          book.currentPage = page;
          saveBook(book);
          if (lastPercent < 100 && getDayPercent() >= 100) {
            toastification.show(
              context: context,
              icon: Icon(Icons.check),
              title: Text('Цель на день выполнена, вы молодец!'),
              autoCloseDuration: const Duration(seconds: 5),
            );
          }
        },
      );
    } else if (page == Page.BookCreate) {
      return BookCreatePage(goHome: goHome, addBook: addBook);
    } else if (page == Page.SetupDayGoal) {
      return setupDayGoal();
    }

    throw Exception();
  }

  Widget? getActionButton() {
    if (page == Page.Home) {
      return FloatingActionButton(
        onPressed: createBook,
        tooltip: 'Create book',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(10), child: getCurrentPage()),
      ),
      floatingActionButton: getActionButton(),
    );
  }
}

class CurrentPageSet extends StatelessWidget {
  CurrentPageSet({
    super.key,
    required this.book,
    required this.goHome,
    required this.update,
  });

  final void Function() goHome;
  final void Function(int page) update;
  final Book book;

  late int page = book.currentPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: goHome,
          child: Row(children: [Icon(Icons.arrow_back), Text("Назад")]),
        ),
        inputField(
          label: "Количество прочитанных страниц",
          defaultValue: page.toString(),
          onChange: (value) {
            page = int.parse(value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => update(page),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                // Set the background color here
                foregroundColor:
                    Colors.white, // Set the text color here (optional)
              ),
              child: Text("Сохранить"),
            ),
          ],
        ),
      ],
    );
  }
}

class BookCreatePage extends StatelessWidget {
  BookCreatePage({super.key, required this.addBook, required this.goHome});

  final void Function(Book book) addBook;
  final void Function() goHome;

  final Book book = Book(title: "", author: "", pages: 0);

  @override
  Widget build(BuildContext context) {
    void create() {
      addBook(book);
    }

    return Column(
      children: [
        TextButton(
          onPressed: goHome,
          child: Row(children: [Icon(Icons.arrow_back), Text("Назад")]),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: LogoPicker(
            book: book,
            pick: (String path) => book.imagePath = path,
          ),
        ),
        inputField(
          label: "Название книги",
          placeholder: "Введите название книги",
          onChange: (value) => book.title = value,
        ),
        inputField(
          label: "Автор",
          placeholder: "Введите автора",
          onChange: (value) => book.author = value,
        ),
        inputField(
          label: "Количество страниц",
          placeholder: "Введите количество страниц",
          onChange: (value) => book.pages = int.parse(value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: create,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                // Set the background color here
                foregroundColor:
                    Colors.white, // Set the text color here (optional)
              ),
              child: Text("Создать"),
            ),
          ],
        ),
      ],
    );
  }
}

class LogoPicker extends StatefulWidget {
  const LogoPicker({super.key, required this.book, required this.pick});

  final Book book;
  final void Function(String) pick;

  @override
  State<LogoPicker> createState() => _LogoPickerState();
}

class _LogoPickerState extends State<LogoPicker> {
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String> saveImageLocally(File image, String subpath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = image.path.split('/').last;
    final path = '$fileName';
    final savedImage = await image.copy('${appDir.path}/$path');
    return path;
  }

  @override
  Widget build(BuildContext context) {
    void pick() async {
      var file = await pickImage();
      if (file == null) return;
      var path = await saveImageLocally(file, widget.book.id.toString());
      setState(() {
        widget.book.imagePath = path;
      });
    }

    var image = widget.book.getImage();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            imageViewer(image),
            Align(
              alignment: Alignment.bottomCenter,
              child:
                  widget.book.imagePath == null
                      ? ElevatedButton(
                        onPressed: pick,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image),
                            Text("Выбрать изображение"),
                          ],
                        ),
                      )
                      : IconButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          // Set the background color here
                          foregroundColor:
                              Colors
                                  .black, // Set the text color here (optional)
                        ),
                        onPressed: pick,
                        icon: Icon(Icons.edit),
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class InputRate extends StatefulWidget {
  const InputRate({
    super.key,
    required this.label,
    required this.onChange,
    this.rate = 0,
  });

  final String label;
  final int? rate;
  final void Function(int) onChange;

  @override
  State<InputRate> createState() => _InputRateState();
}

class _InputRateState extends State<InputRate> {
  int? value;

  void update(int value) {
    setState(() {
      widget.onChange(value);
      this.value = value;
    });
  }

  Widget star(int index) {
    return GestureDetector(
      onTap: () => update(index),
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Icon(
          Icons.star,
          color:
              (value ?? widget.rate ?? 0) >= index
                  ? Colors.orangeAccent
                  : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: Text(
              widget.label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(children: [star(0), star(1), star(2), star(3), star(4)]),
        ],
      ),
    );
  }
}

Widget inputField({
  required String label,
  required void Function(String) onChange,
  String? defaultValue,
  String placeholder = "",
  int maxLines = 1,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
          child: Text(
            label,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        TextFormField(
          onChanged: onChange,
          initialValue: defaultValue,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
      ],
    ),
  );
}

class BooksGroup extends StatelessWidget {
  const BooksGroup({
    super.key,
    required this.books,
    required this.title,
    required this.setPageCallback,
    required this.editCallback,
    required this.goReadCallback,
    required this.banCallback,
    this.elementInfo = false,
  });

  final bool elementInfo;
  final String title;
  final List<Book> books;
  final void Function(Book) setPageCallback;
  final void Function(Book) editCallback;
  final void Function(Book) goReadCallback;
  final void Function(Book) banCallback;

  @override
  Widget build(BuildContext context) {
    List<Widget> bookList = [];
    for (var book in books) {
      bookList.add(
        BookView(
          book: book,
          viewInfo: elementInfo,
          setPageCallback: setPageCallback,
          editCallback: editCallback,
          goReadCallback: goReadCallback,
          banCallback: banCallback,
        ),
      );
    }
    if (books.isEmpty) {
      bookList.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Пока нет книг в этом разделе")],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
        Wrap(children: bookList),
      ],
    );
  }
}

Widget ImagePlaceholder() {
  return AspectRatio(
    aspectRatio: 0.8,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      // по желанию
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Color.fromRGBO(100, 100, 100, 1),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Icon(Icons.image, size: 40, color: Colors.grey),
          ),
        ),
      ),
    ),
  );
}

Widget imageViewer(Future<File?> image) {
  return FutureBuilder(
    future: image,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return ImagePlaceholder();
      }

      return AspectRatio(
        aspectRatio: 0.8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          // по желанию
          child: Image.file(snapshot.data!, fit: BoxFit.cover),
        ),
      );
    },
  );
}

class BookView extends StatelessWidget {
  const BookView({
    super.key,
    required this.book,
    this.viewInfo = false,
    required this.setPageCallback,
    required this.editCallback,
    required this.goReadCallback,
    required this.banCallback,
  });

  final bool viewInfo;
  final Book book;
  final void Function(Book) setPageCallback;
  final void Function(Book) editCallback;
  final void Function(Book) goReadCallback;
  final void Function(Book) banCallback;

  void changeStatus() {
    // do smth
  }

  Widget progress() {
    int percentage = book.getPercentage();
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: SizedBox(
            height: 10,
            child: LinearProgressIndicator(value: percentage * 0.01),
          ),
        ),
        Padding(padding: EdgeInsets.all(5), child: Text('$percentage%')),
      ],
    );
  }

  Widget button() {
    return ElevatedButton(onPressed: changeStatus, child: Text("Отложить"));
  }

  @override
  Widget build(BuildContext context) {
    var image = book.getImage();
    if (viewInfo) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => editCallback(book),
                    child: SizedBox(height: 150, child: imageViewer(image)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => editCallback(book),
                          child: Padding(
                            padding: EdgeInsets.all(3),
                            child: Text(
                              book.title,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          book.author,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => setPageCallback(book),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("Текущая страница"),
                              Icon(Icons.edit),
                              Text(book.currentPage.toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              progress(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: ElevatedButton.styleFrom(
                        //   backgroundColor: Colors.blueAccent,
                        // Set the background color here
                        foregroundColor:
                            Colors.black, // Set the text color here (optional)
                      ),
                      onPressed: () => banCallback(book),
                      child: Text("Отложить"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => goReadCallback(book),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                imageViewer(image),
                Padding(
                  padding: EdgeInsets.all(3),
                  child: Text(
                    book.title,
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
                progress(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
