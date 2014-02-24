DictionaryBot
=============

An IRC bot that provides definitions for words in the English language.

##Usage

`!dictionary help`
Provides usage help.

###Define a Word

`!dictionary define <word> [results=3]`
Define a word giving a specified number of results. The number of
results is limited to at most ten.

`define: <word>`
Define a word giving the first three results.

DefineBot will to the best of its ability try to define a given word
even if it is mispelled.

###Word of The Day

`!wordoftheday [date=today]`, or
`!wotd`
Gives a word of the day of at a specific date. A given date must be of the
format yyyy-MM-dd or the words 'yesterday', 'today', or 'tomorrow'.

##Requirements

* Ruby >= 1.9.0
* Cinch IRC libaray @ [github.com](https://github.com/cinchrb/cinch)
* Wordnik Ruby API @ [github.com](http://github.com/wordnik/wordnik-ruby))
