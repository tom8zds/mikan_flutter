import 'package:flutter/cupertino.dart';
import 'package:mikan_flutter/core/http.dart';
import 'package:mikan_flutter/core/repo.dart';
import 'package:mikan_flutter/ext/extension.dart';
import 'package:mikan_flutter/model/bangumi.dart';
import 'package:mikan_flutter/model/bangumi_row.dart';
import 'package:mikan_flutter/model/carousel.dart';
import 'package:mikan_flutter/model/index.dart';
import 'package:mikan_flutter/model/record_item.dart';
import 'package:mikan_flutter/model/season.dart';
import 'package:mikan_flutter/model/user.dart';
import 'package:mikan_flutter/model/year_season.dart';
import 'package:mikan_flutter/providers/models/base_model.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class IndexModel extends CancelableBaseModel {
  List<YearSeason> _years = [];
  List<Season> _seasons = [];
  List<BangumiRow> _bangumiRows = [];
  Map<String, List<RecordItem>> _rss = {};
  List<Carousel> _carousels = [];
  Season _selectedSeason;
  User _user;
  String _tapBangumiListItemFlag;
  String _tapBangumiRssItemFlag;
  String _tapBangumiCarouselItemFlag;

  GlobalKey bangumiListGlobalKey;

  String get tapBangumiCarouselItemFlag => _tapBangumiCarouselItemFlag;

  set tapBangumiCarouselItemFlag(String value) {
    _tapBangumiCarouselItemFlag = value;
    notifyListeners();
  }

  String get tapBangumiRssItemFlag => _tapBangumiRssItemFlag;

  set tapBangumiRssItemFlag(String value) {
    _tapBangumiRssItemFlag = value;
    notifyListeners();
  }

  String get tapBangumiListItemFlag => _tapBangumiListItemFlag;

  set tapBangumiListItemFlag(String value) {
    _tapBangumiListItemFlag = value;
    notifyListeners();
  }

  bool _seasonLoading = false;

  bool get seasonLoading => _seasonLoading;

  Season get selectedSeason => _selectedSeason;

  List<Season> get seasons => _seasons;

  final RefreshController _refreshController =
  RefreshController(initialRefresh: true);

  RefreshController get refreshController => _refreshController;

  IndexModel() {
    loadIndex();
  }

  Future loadIndex() async {
    if (this._seasonLoading) return "加载中，请稍候...".toast();
    await (this + _loadIndex());
  }

  _loadIndex() async {
    this._seasonLoading = true;
    notifyListeners();
    final Resp resp = await Repo.index();
    this._seasonLoading = false;
    if (resp.success) {
      final Index index = resp.data;
      if (index == null) return;
      this._years = index.years;
      this._seasons = [];
      for (final YearSeason ys in this._years) {
        this._seasons.addAll(ys.seasons);
        for (final Season season in ys.seasons) {
          if (season.active) {
            this._selectedSeason = season;
          }
        }
      }
      if (this._selectedSeason == null && this._seasons.isNotEmpty) {
        this._selectedSeason = this._seasons[0];
      }
      this._bangumiRows = index.bangumiRows;
      this._rss = index.rss;
      this._carousels = index.carousels;
      this._user = index.user;
      "加载完成...".toast();
    } else {
      if (resp.msg.isNotBlank) {
        resp.msg.toast();
      } else {
        "加载失败...".toast();
      }
    }
    notifyListeners();
  }

  List<BangumiRow> get bangumiRows => _bangumiRows;

  Map<String, List<RecordItem>> get rss => _rss;

  List<Carousel> get carousels => _carousels;

  List<YearSeason> get years => _years;

  User get user => _user;

  loadSeason(final Season season) async {
    if (this._seasonLoading) return "加载中，请稍候...".toast();
    this._selectedSeason = season;
    notifyListeners();
    this._seasonLoading = true;
    final Resp resp = await Repo.season(
      this._selectedSeason.year,
      this._selectedSeason.season,
    );
    this._seasonLoading = false;
    if (this.disposed) return;
    if (resp.success) {
      this._bangumiRows = resp.data;
      "加载完成...".toast();
    } else {
      if (resp.msg.isNotBlank) {
        resp.msg.toast();
      } else {
        "加载失败...".toast();
      }
    }
    notifyListeners();
  }

  subscribeBangumi(final Bangumi bangumi) {
    Repo.subscribeBangumi(bangumi.subscribed, bangumi.id).then((resp) async {
      if (resp.success) {
        this.tapBangumiListItemFlag = "bangumi:${bangumi.id}:${bangumi.cover}";
        notifyListeners();
        Future.delayed(
          Duration(milliseconds: 360),
          () {
            bangumi.subscribed = !bangumi.subscribed;
            this.tapBangumiListItemFlag = null;
            notifyListeners();
          },
        );
      } else {
        if (resp.msg.isNotBlank) {
          resp.msg.toast();
        } else {
          "操作失败...".toast();
        }
      }
    });
  }
}

typedef LoadSeasonIndex = int Function(int currIndex);
