import 'dart:math';

import 'package:flutter/material.dart';

enum BookState {
  New, // новая
  Reading, // в процессе чтения
  Abandoned, // заброшена
}

enum Page { Home, BookCreate, BookEdit, CurrentPageEdit, SetupDayGoal }

class Book {
  int id = 0;
  String title;
  String author;
  int pages;
  int currentPage;
  BookState state;

  Book({
    required this.title,
    required this.author,
    required this.pages,
    this.currentPage = 0,
    this.state = BookState.New,
  }) {
    id = DateTime.now().millisecondsSinceEpoch;
  }

  int getPercentage() {
    if (currentPage == 0) return 0;
    return (min(currentPage, pages) / pages * 100.0).round();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  List<Book> books = [
    Book(title: "asdf", author: "asdf", pages: 1234, currentPage: 500),
    Book(title: "slsfdkjg", author: "s;dflkj", pages: 5),
  ];

  void addBook(Book book, {redirect = true}) {
    setState(() {
      books.add(book);
      if (redirect) {
        page = Page.Home;
      }
    });
  }

  void saveBook(int bookIndex, Book book, {redirect = true}) {
    setState(() {
      books[bookIndex] = book;
      if (redirect) {
        page = Page.Home;
      }
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

  void editBook(int bookIndex) {
    setState(() {
      page = Page.BookEdit;
      currentBookIndex = bookIndex;
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

  Widget home() {
    return SingleChildScrollView(
      child: Column(
        children: [
          BooksGroup(
            books:
                books.where((book) => book.state == BookState.Reading).toList(),
            title: "Читаю",
            elementInfo: true,
            setPageCallback: (book) => setCurrentBookPage(book.id),
          ),
          BooksGroup(
            books: books.where((book) => book.state == BookState.New).toList(),
            title: "В процессе чтения",
            elementInfo: true,
            setPageCallback: (book) => setCurrentBookPage(book.id),
          ),
          BooksGroup(
            books:
                books
                    .where((book) => book.state == BookState.Abandoned)
                    .toList(),
            title: "Заброшенные",
            elementInfo: true,
            setPageCallback: (book) => setCurrentBookPage(book.id),
          ),
        ],
      ),
    );
  }

  Widget bookEdit(Book book) {
    return Placeholder();
  }

  Widget currentPageEdit(Book book) {
    return Column(
      children: [
        TextButton(
          onPressed: goHome,
          child: Row(children: [Icon(Icons.arrow_back), Text("Назад")]),
        ),
        inputField(
          label: "Количество прочитанных страниц",
          defaultValue: book.currentPage.toString(),
          onChange: (value) => book.currentPage = int.parse(value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => saveBook(currentBookIndex!, book),
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

  Widget bookCreate() {
    String title = "";
    String author = "";
    String pagesCount = "";

    void create() {
      Book book = Book(
        title: title,
        author: author,
        pages: int.parse(pagesCount),
      );
      addBook(book);
    }

    return Column(
      children: [
        TextButton(
          onPressed: goHome,
          child: Row(children: [Icon(Icons.arrow_back), Text("Назад")]),
        ),
        inputField(
          label: "Название книги",
          placeholder: "Введите название книги",
          onChange: (value) => title = value,
        ),
        inputField(
          label: "Автор",
          placeholder: "Введите автора",
          onChange: (value) => author = value,
        ),
        inputField(
          label: "Количество страниц",
          placeholder: "Введите количество страниц",
          onChange: (value) => pagesCount = value,
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

  Widget setupDayGoal() {
    return Placeholder();
  }

  Widget getCurrentPage() {
    if (page == Page.Home) {
      return home();
    } else if (page == Page.BookEdit) {
      return bookEdit(books[currentBookIndex!]);
    } else if (page == Page.CurrentPageEdit) {
      return currentPageEdit(books.firstWhere((book) => book.id == currentBookIndex));
    } else if (page == Page.BookCreate) {
      return bookCreate();
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
      body: Padding(padding: EdgeInsets.all(10), child: getCurrentPage()),
      floatingActionButton: getActionButton(),
    );
  }
}

Widget inputField({
  required String label,
  required void Function(String) onChange,
  String? defaultValue,
  String placeholder = "",
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          onChanged: onChange,
          initialValue: defaultValue,
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
    this.elementInfo = false,
  });

  final bool elementInfo;
  final String title;
  final List<Book> books;
  final void Function(Book) setPageCallback;

  @override
  Widget build(BuildContext context) {
    List<Widget> bookList = [];
    for (var book in books) {
      bookList.add(
        BookView(
          book: book,
          viewInfo: elementInfo,
          setPageCallback: setPageCallback,
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

class BookView extends StatelessWidget {
  const BookView({
    super.key,
    required this.book,
    this.viewInfo = false,
    required this.setPageCallback,
  });

  final bool viewInfo;
  final Book book;
  final void Function(Book) setPageCallback;

  void changeStatus() {
    // do smth
  }

  Widget progress() {
    int percentage = book.getPercentage();
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: 300,
          height: 10,
          child: LinearProgressIndicator(value: percentage * 0.01),
        ),
        Text('$percentage%'),
      ],
    );
  }

  Widget button() {
    return ElevatedButton(onPressed: changeStatus, child: Text("Отложить"));
  }

  @override
  Widget build(BuildContext context) {
    if (viewInfo) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.all(3),
                child: Text(
                  book.title,
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
              Text(
                book.author,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Row(
                children: [
                  Text("Текущая страница"),
                  TextButton(
                    onPressed: () => setPageCallback(book),
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        Text(book.currentPage.toString()),
                      ],
                    ),
                  ),
                ],
              ),
              progress(),
            ],
          ),
        ),
      );
    }
    return const Placeholder();
  }
}
