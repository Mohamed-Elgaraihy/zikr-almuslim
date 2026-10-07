final _tashkeel = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]');

String stripTashkeel(String text) => text.replaceAll(_tashkeel, '');
