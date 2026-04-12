// responsible of searching through the country list

import 'package:diacritic/diacritic.dart';

import 'searchable_country.dart';

class CountryFinder {
  /// Converts Eastern Arabic-Indic (٠١٢٣٤٥٦٧٨٩, U+0660–U+0669) and
  /// Extended Arabic-Indic (۰۱۲۳۴۵۶۷۸۹, U+06F0–U+06F9) numerals typed via
  /// Arabic/Persian keyboard layouts to ASCII digits so dial-code and ISO
  /// searches work regardless of the active system keyboard.
  static String _normalizeNumerals(String text) {
    return text.runes
        .map((rune) {
          if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30;
          if (rune >= 0x06F0 && rune <= 0x06F9) return rune - 0x06F0 + 0x30;
          return rune;
        })
        .map(String.fromCharCode)
        .join();
  }

  List<SearchableCountry> whereText({
    required String text,
    required List<SearchableCountry> countries,
  }) {
    // Normalize Eastern Arabic / Extended Arabic-Indic numerals to ASCII digits
    text = _normalizeNumerals(text);

    // remove + if search text starts with +
    if (text.startsWith('+')) {
      text = text.substring(1);
    }
    // reset search
    if (text.isEmpty) {
      return countries;
    }

    // if the txt is a number we check the country code instead
    final asInt = int.tryParse(text);
    final isInt = asInt != null;
    if (isInt) {
      // toString to remove any + in front if its an int
      return _filterByCountryCallingCode(
          countryCallingCode: text, countries: countries);
    } else {
      return _filterByName(searchText: text, countries: countries);
    }
  }

  List<SearchableCountry> _filterByCountryCallingCode({
    required String countryCallingCode,
    required List<SearchableCountry> countries,
  }) {
    int computeSortScore(SearchableCountry country) =>
        country.dialCode.startsWith(countryCallingCode) ? 0 : 1;

    return countries
        .where((country) => country.dialCode.contains(countryCallingCode))
        .toList()
      // puts the closest match at the top
      ..sort((a, b) => computeSortScore(a) - computeSortScore(b));
  }

  List<SearchableCountry> _filterByName({
    required String searchText,
    required List<SearchableCountry> countries,
  }) {
    searchText = removeDiacritics(searchText.toLowerCase());

    // 0 = exact ISO match (e.g. "us"), 1 = name starts-with, 2 = name or ISO contains
    int computeSortScore(SearchableCountry country) {
      final iso = country.isoCode.name.toLowerCase();
      if (iso == searchText) return 0;
      if (country.searchableName.startsWith(searchText)) return 1;
      return 2;
    }

    return countries
        .where((country) =>
            country.searchableName.contains(searchText) ||
            country.isoCode.name.toLowerCase().contains(searchText))
        .toList()
      // puts the closest match at the top
      ..sort((a, b) => computeSortScore(a) - computeSortScore(b));
  }
}
