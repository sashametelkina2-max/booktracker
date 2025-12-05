import 'dart:math';

import 'package:flutter/material.dart';

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

class Book {
  int id = 0;
  String title;
  String author;
  int pages;
  int currentPage;
  BookState state;

  int? rate;
  String notes = "";

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
    return getValuePercentage(currentPage, pages);
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Book tracker'),
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
  int dayPagesGoal = 10;
  int currentDayPages = 5;

  void addBook(Book book, {bool redirect = true}) {
    setState(() {
      books.add(book);
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

  Widget dayGoalButton() {
    int percent = getValuePercentage(currentDayPages, dayPagesGoal);
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

  Widget home() {
    return SingleChildScrollView(
      child: Column(
        children: [
          dayGoalButton(),
          BooksGroup(
            books:
                books.where((book) => book.state == BookState.Reading).toList(),
            title: "Читаю",
            elementInfo: true,
            setPageCallback: (book) => setCurrentBookPage(book.id),
            editCallback: (book) => editBook(book.id),
          ),
          BooksGroup(
            books: books.where((book) => book.state == BookState.New).toList(),
            title: "В процессе чтения",
            elementInfo: true,
            setPageCallback: (book) => setCurrentBookPage(book.id),
            editCallback: (book) => editBook(book.id),
          ),
          BooksGroup(
            books:
                books
                    .where((book) => book.state == BookState.Abandoned)
                    .toList(),
            title: "Заброшенные",
            elementInfo: true,
            setPageCallback: (book) => setCurrentBookPage(book.id),
            editCallback: (book) => editBook(book.id),
          ),
        ],
      ),
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

  Widget currentPageEdit(Book book) {
    int previousPages = book.currentPage;

    void update() {
      saveBook(book);
      int delta = book.currentPage - previousPages;
      setState(() {
        currentDayPages += delta;
      });
    }

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
              onPressed: update,
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
      return currentPageEdit(
        books.firstWhere((book) => book.id == currentBookIndex),
      );
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
    required this.editCallback,
    this.elementInfo = false,
  });

  final bool elementInfo;
  final String title;
  final List<Book> books;
  final void Function(Book) setPageCallback;
  final void Function(Book) editCallback;

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
    required this.editCallback,
  });

  final bool viewInfo;
  final Book book;
  final void Function(Book) setPageCallback;
  final void Function(Book) editCallback;

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
              GestureDetector(
                onTap: () => editCallback(book),
                child: Padding(
                  padding: EdgeInsets.all(3),
                  child: Text(
                    book.title,
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
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
