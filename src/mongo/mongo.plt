:- include(misc(common)).

:- use_module(misc(util), []).

database('prolongo_test').
collection('testcoll').

up(Mongo) :-
    mongo:new_mongo(Mongo0),
    database(Database),
    mongo:use_database(Mongo0, Database, Mongo).

down(Mongo) :-
    mongo:free_mongo(Mongo).

:- begin_tests('mongo:insert/3').

test('insert', [setup(up(Mongo)),cleanup(down(Mongo))]) :-
    util:ms_since_epoch(MilliSeconds),
    Document =
    [
        hello - [åäö,5.05],
        now   - utc(MilliSeconds)
    ],
    collection(Collection),
    mongo:insert(Mongo, Collection, Document).

:- end_tests('mongo:insert/3').

:- begin_tests('mongo:command/3').

test('drop collection', [setup(up(Mongo)),cleanup(down(Mongo))]) :-
    collection(Collection),
    mongo:drop_collection(Mongo, Collection, Result),
    bson:doc_get(Result, ok, 1.0).

/*
% Takes a bit too long when MongoDB reallocates the collection later.
test('drop database', [setup(up(Mongo)),cleanup(down(Mongo))]) :-
    mongo:drop_database(Mongo).
*/

:- end_tests('mongo:command/3').
