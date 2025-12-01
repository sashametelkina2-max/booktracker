import 'dart:math';

import 'package:flutter/material.dart';

enum BookState {
  New, // новая
  Reading, // в процессе чтения
  Abandoned, // заброшена
}

enum Page { Home, BookCreate, BookEdit }

class Book {
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
  });

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
  List<Book> books = [
    Book(title: "asdf", author: "asdf", pages: 1234, currentPage: 500),
    Book(title: "slsfdkjg", author: "s;dflkj", pages: 5),
  ];

  void createBook() {
    setState(() {
      page = Page.BookCreate;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
      body: Padding(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              BooksGroup(books: books, title: "Читаю", elementInfo: true),
              BooksGroup(
                books: books,
                title: "В процессе чтения",
                elementInfo: true,
              ),
              BooksGroup(books: books, title: "Заброшенные", elementInfo: true),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createBook,
        tooltip: 'Create book',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class BooksGroup extends StatelessWidget {
  const BooksGroup({
    super.key,
    required this.books,
    required this.title,
    this.elementInfo = false,
  });

  final bool elementInfo;
  final String title;
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    List<BookView> bookList = [];
    for (var book in books) {
      bookList.add(BookView(book: book, viewInfo: elementInfo));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Wrap(children: bookList),
      ],
    );
  }
}

class BookView extends StatelessWidget {
  const BookView({super.key, required this.book, this.viewInfo = false});

  final bool viewInfo;
  final Book book;

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
              progress(),
            ],
          ),
        ),
      );
    }
    return const Placeholder();
  }
}
