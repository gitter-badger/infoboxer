# Infoboxer's change log

## 0.2.1 (2015-12-21)

* `infoboxer` binary properly registered.

## 0.2.0 (2015-12-21)

* MediaWiki backend changed to (our own handcrafted)
  [mediawiktory](https://github.com/molybdenum-99/mediawiktory);
* Added page lists fetching like `MediaWiki#category(categoryname)`,
  `MediaWiki#search(search_phrase)`;
* `MediaWiki#get` now can fetch any number of pages at once (it was only
  50 in previous versions);
* `bin/infoboxer` console added for quick experimenting;
* `Template#to_h` added for quick information extraction;
* many small bugfixes and echancements. 

## 0.1.2.1 (2015-12-04)

* Small bug with newlines in templates fixed.

## 0.1.2 (2015-08-18)

Aaaaand, rrrrrelease it into the wilde!

* `ImageCaption` class added;
* Smallest refactorings;
* More documentation fixes.


## 0.1.1 (2015-08-11)

Basically, preparing for wider release!

* Small refactorings;
* Documentation fixes.

## 0.1.0 (2015-08-07)

Initial (ok, I know it's typically called 0.0.1, but here's work of
three monthes, numerous documentations and examples and so on... so, let
it be 0.1.0).
