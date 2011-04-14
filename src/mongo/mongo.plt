:- include(misc(common)).

database('prolongo_test').
collection('testcoll').
database_dot_collection('prolongo_test.testcoll').

ms_since_epoch(MilliSeconds) :-
    core:get_time(FloatSeconds),
    FloatMilliSeconds is FloatSeconds * 1000,
    MilliSeconds is floor(FloatMilliSeconds).

doc_value([], _Key, null).
doc_value([Key-Value|_Pairs], Key, Value) :- !.
doc_value([_Pair|Pairs], Key, Value) :-
    doc_value(Pairs, Key, Value).

:- begin_tests('mongo:insert/3').

test('insert',
[
    setup(mongo:new_mongo(Mongo)),
    cleanup(mongo:free_mongo(Mongo))
]) :-
    ms_since_epoch(MilliSeconds),
    Document =
    [
        hello - [åäö,5.05],
        now   - utc(MilliSeconds)
    ],
    database_dot_collection(DbDotColl),
    mongo:insert(Mongo, Document, DbDotColl).

:- end_tests('mongo:insert/3').

:- begin_tests('mongo:command/3').

test('drop collection',
[
    setup(mongo:new_mongo(Mongo)),
    cleanup(mongo:free_mongo(Mongo))
]) :-
    Command =
    [
        drop - Coll
    ],
    collection(Coll),
    database(Db),
    mongo:command(Mongo, Command, Db, Result),
    doc_value(Result, ok, 1.0).

/*
% Takes a bit too long when MongoDB reallocates the collection later.
test('drop database',
[
    setup(mongo:new_mongo(Mongo)),
    cleanup(mongo:free_mongo(Mongo))
]) :-
    Command =
    [
        dropDatabase - 1
    ],
    database(Db),
    mongo:command(Mongo, Command, Db).
*/

:- end_tests('mongo:command/3').