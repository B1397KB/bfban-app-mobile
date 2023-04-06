abstract class Paging {
  int? skip;
  int? _minskip = 0;
  int? limit;

  Paging({
    this.limit = 40,
    this.skip = 1,
  });

  resetPage() {
    skip = _minskip;
  }

  nextPage({int count = 1}) {
    skip = skip! + count;
  }

  prevPage({int count = 1}) {
    if (skip! <= _minskip!) return;
    skip = skip! - count;
  }

  Map<String, dynamic> get pageToMap => Map.from({
        "skip": skip,
        "limit": limit,
      });
}

abstract class Sort {
  String? sort;

  Sort({
    this.sort,
  });
}
