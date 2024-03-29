import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:restock_client/controllers/app_context.dart';
import 'package:restock_client/models/product.dart';

import 'dart:math';

const _imageLinks = [
  "https://www.nvidia.com/content/dam/en-zz/Solutions/homepage/sfg/geforce-ampere-rtx-30-series-learn-nv-sfg-295x166@2x.jpg",
  "https://venturebeat.com/wp-content/uploads/2019/09/AMD-Ryzen-2nd-Gen_8-2060x1057.png",
  "https://cdn.vox-cdn.com/thumbor/XBkbwCeopp8ccumdPDcjWxmLkvs=/1400x1400/filters:format(jpeg)/cdn.vox-cdn.com/uploads/chorus_asset/file/22015299/vpavic_4278_20201030_0150.jpg",
];

class HomePage extends StatefulWidget {
  HomePage(this.products);

  final List products;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = Color.fromRGBO(41, 60, 79, 1);

  List<Product> _productList;

  Image _headerImage;

  final List<String> _tabNames = ['All', 'GPUs', 'CPUs', 'Consoles'];
  List _tabMembership = [
    (product) => true,
    (product) => product.type == ProductType.GPU,
    (product) => product.type == ProductType.CPU,
    (product) => product.type == ProductType.Console,
  ]; // membership tests for the contents of each tab

  pickRandom(arr) => arr[new Random().nextInt(arr.length)];

  @override
  void initState() {
    super.initState();

    _productList = widget.products;
    WidgetsBinding.instance.addPostFrameCallback((_) => sortProducts);

    _headerImage = Image.network(
      pickRandom(_imageLinks),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabNames.length,
      child: Scaffold(
        // backgroundColor: primaryColor,
        body: NestedScrollView(
          headerSliverBuilder: _buildAppBar,
          body: Stack(
            children: [
              _buildProductViews(),
              // could have like a FAB or something here
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBar(BuildContext context, bool innerBoxIsScrolled) {
    final screenHeight = MediaQuery.of(context).size.height;
    return [
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverSafeArea(
          top: false,
          // NOTE: The above 3 widgets prevent the body from going under the app bar
          // they cause a slight 'bump' when scrolling up though for a list that spans
          // more than the screen
          sliver: SliverAppBar(
            expandedHeight: screenHeight * 0.4,
            elevation: 4,
            backgroundColor: primaryColor,
            floating: false,
            pinned: true,

            title: Text(
              "Restocker",
              style: TextStyle(color: Colors.white, fontSize: 22.0),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: _buildHeaderVisual(),
            ),
            leading: IconButton(
              icon: Icon(Icons.menu, size: 25),
              onPressed: () {},
            ),
            bottom: TabBar(
              tabs: _tabNames.map((name) => Tab(text: name)).toList(),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildHeaderVisual() {
    //TODO: Graphs?
    return _headerImage;
  }

  Widget _buildProductViews() {
    List<Widget> tabs = List();
    for (int i = 0; i < _tabMembership.length; i++) {
      var belongsInTab = _tabMembership[i];
      List tabProducts =
          _productList.where((product) => belongsInTab(product)).toList();

      var tab = ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: tabProducts.length,
        itemBuilder: (context, i) => _buildProductTile(tabProducts[i]),
      );
      tabs.add(tab);
    }

    return TabBarView(
      children: tabs,
      physics: BouncingScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
    );
  }

  Widget _buildProductTile(Product product) {
    AppContext appContext = Provider.of<AppContext>(context);

    // Product product = _productList[productIndex];
    bool isFollowing = appContext.isFollowing(product);

    return Card(
      elevation: .5,
      child: SwitchListTile.adaptive(
        activeColor: primaryColor,
        title: Text(
          '${product.name}',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        value: isFollowing,
        secondary: SizedBox(
          height: 40,
          child: Image.asset(Product.getIcon(product, isFollowing)),
        ),
        onChanged: (bool value) async {
          // actually (un)follow the product
          setState(() {
            if (isFollowing)
              appContext.unfollowProduct(product);
            else {
              appContext.followProduct(product);
            }
          });

          // update ordering of product list
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              sortProducts();
            });
          });
        },
      ),
    );
  }

  void sortProducts() {
    /* Sort product list so followed products are at top
    */
    AppContext appContext = Provider.of<AppContext>(context);
    Map<Product, bool> isFollowing = Map.fromIterable(
      _productList,
      key: (p) => p,
      value: (p) => appContext.isFollowing(p),
    );

    // sort true then false
    _productList.sort((a, b) {
      if (!(isFollowing[a] ^ isFollowing[b])) {
        // equal
        return 0;
      }

      // sorts low to high --> a should be less than b if a = true and b = false
      return isFollowing[a] && !isFollowing[b] ? -1 : 1;
    });
  }
}
