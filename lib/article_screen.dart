import 'package:flutter/material.dart';

class ArticlesPage extends StatefulWidget {
  @override
  _ArticlesPageState createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Number of categories
      child: Scaffold(
        appBar: AppBar(
          title: Text('Articles'),
          backgroundColor: Colors.blue, // Adjust theme color
          bottom: TabBar(
            isScrollable: true, // Allows scrolling if too many categories
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Newest"),
              Tab(text: "Health"),
              Tab(text: "COVID-19"),
              Tab(text: "Lifecycle"),
              Tab(text: "Trending"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ArticlesList(category: "Newest"),
            ArticlesList(category: "Health"),
            ArticlesList(category: "COVID-19"),
            ArticlesList(category: "Lifecycle"),
            ArticlesList(category: "Trending"),
          ],
        ),
      ),
    );
  }
}

class ArticlesList extends StatelessWidget {
  final String category;
  const ArticlesList({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Articles in $category",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
