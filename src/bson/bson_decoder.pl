% BSON decoder.

:- module(_, [decode/2]).

:- use_module(bson_bits).

:- encoding(utf8).

:- begin_tests(bson_decoder).

%%  decode(+Bson:list, -Term) is semidet.
%
%   True if Term is the BSON document represented by the list
%   of bytes (0..255) in Bson.

test('valid utf8', [true(Got == Expected)]) :-
    Bson =
    [
        xxx_not_impl,0,0,0, % Length of top doc.
        0x02, % String tag.
            0xc3,0xa4, 0, % Ename, "ä\0".
            6,0,0,0, % String's byte length, incl. nul.
            0xc3,0xa4, 0, 0xc3,0xa4, 0, % String data, "ä\0ä\0".
        0 % End of top doc.
    ],
    Expected =
    [
        'ä': 'ä\0ä'
    ],
    bson_decoder:decode(Bson, Got).

test('nuls not allowed in ename', [throws(bson_error(_))]) :-
    Bson =
    [
        xxx_not_impl,0,0,0, % Length of top doc.
        0x02, % String tag.
            0xc3,0xa4, 0, 0xc3,0xa4, 0, % Ename, "ä\0ä\0".
            3,0,0,0, % String's byte length, incl. nul.
            0xc3,0xa4, 0, % String data, "ä\0".
        0 % End of top doc.
    ],
    bson_decoder:decode(Bson, _Got).

test('int32', [true(Got == Expected)]) :-
    Bson =
    [
        xxx_not_impl,0,0,0, % Length of top doc.
        0x10, % Int32 tag
            104,101,108,108,111, 0, % Ename "hello\0".
            32,0,0,0, % Int32 data, 32.
        0 % End of top doc.
    ],
    Expected =
    [
        'hello': 32
    ],
    bson_decoder:decode(Bson, Got).

test('int64', [true(Got == Expected)]) :-
    Bson =
    [
        xxx_not_impl,0,0,0, % Length of top doc.
        0x12, % Int64 tag
            104,101,108,108,111, 0, % Ename "hello\0".
            32,0,0,0, 0,0,0,0, % Int64 data, 32.
        0 % End of top doc.
    ],
    Expected =
    [
        'hello': 32
    ],
    bson_decoder:decode(Bson, Got).

test('float', [true(Got == Expected)]) :-
    Bson =
    [
        xxx_not_impl,0,0,0, % Length of top doc.
        0x01, % Double tag.
            104,101,108,108,111, 0, % Ename "hello\0".
            51,51,51,51, 51,51,20,64, % Double data, 5.05.
        0 % End of top doc.
    ],
    Expected =
    [
        'hello': 5.05
    ],
    bson_decoder:decode(Bson, Got).

test('embedded array', [true(Got == Expected)]) :-
    Bson =
    [
        49,0,0,0, % Length of top doc.
        0x04, % Array tag.
            66,83,79,78, 0, % Ename "BSON\0".
            38,0,0,0, % Length of embedded doc (array).
            0x02, % String tag.
                48, 0, % Ename, index 0 ("0\0").
                8,0,0,0, % String's byte length, incl. nul.
                97,119,101,115,111,109,101, 0, % String data, "awesome\0".
            0x01, % Double tag.
                49, 0, % Ename, index 1 ("1\0").
                51,51,51,51,51,51,20,64, % Double 8-byte data, 5.05.
            0x10, % Int32 tag.
                50, 0, % Ename, index 2 ("2\0").
                194,7,0,0, % Int32 data, 1986.
            0, % End of embedded doc (array).
        0 % End of top doc.
    ],
    Expected =
    [
        'BSON':
            [
                '0': 'awesome',
                '1': 5.05,
                '2': 1986
            ]
    ],
    bson_decoder:decode(Bson, Got).

test('invalid bson, missing terminating nul', [throws(bson_error(_))]) :-
    Bson =
    [
        xxx_not_impl,0,0,0, % Length of top doc.
        0x10, % Int32 tag
            104,101,108,108,111, 0, % Ename "hello\0".
            32,0,0,0 % Int32 data, 32.
        % Missing nul at end-of-doc.
    ],
    bson_decoder:decode(Bson, _Got).

:- end_tests(bson_decoder).

decode(Bson, Term) :-
    phrase(decode(Term), Bson),
    !.
decode(_Bson, _Term) :-
    throw(bson_error('Invalid BSON document.')).

decode(Term) -->
    document(Term).

document(Elements) -->
    length(_Length), % XXX Ignored for now. Validate how much?
    element_list(Elements),
    end.

element_list([Element|Elements]) -->
    element(Element),
    !,
    element_list(Elements).
element_list([]) --> [].

element(Element) -->
    [0x01],
    !,
    element_double(Element).
element(Element) -->
    [0x02],
    !,
    element_utf8_string(Element).
element(Element) -->
    [0x04],
    !,
    element_document(Element).
element(Element) -->
    [0x10],
    !,
    element_int32(Element).
element(Element) -->
    [0x12],
    !,
    element_int64(Element).

element_document(Pair) -->
    key_name(Ename),
    value_document(Doc),
    { key_value_pair(Ename, Doc, Pair) }.

element_double(Pair) -->
    key_name(Ename),
    value_double(Double),
    { key_value_pair(Ename, Double, Pair) }.

element_utf8_string(Pair) -->
    key_name(Ename),
    value_string(String),
    { key_value_pair(Ename, String, Pair) }.

element_int32(Pair) -->
    key_name(Ename),
    value_int32(Integer),
    { key_value_pair(Ename, Integer, Pair) }.

element_int64(Pair) -->
    key_name(Ename),
    value_int64(Integer),
    { key_value_pair(Ename, Integer, Pair) }.

key_name(Ename) -->
    cstring(CharList),
    { bytes_to_utf8_atom(CharList, Ename) }.

key_value_pair(Key, Value, Key:Value).

value_document(Doc) -->
    document(Doc).

value_string(String) -->
    length(Length),
    utf8_string(ByteList, Length),
    { bytes_to_utf8_atom(ByteList, String) }.

utf8_string(ByteList, Length) -->
    { LengthMinusNul is Length - 1 },
    utf8_string(ByteList, 0, LengthMinusNul).

utf8_string([Byte|Bs], Length0, Length) -->
    { Length0 < Length },
    !,
    [Byte], % May be nul.
    { Length1 is Length0 + 1 },
    utf8_string(Bs, Length1, Length).
utf8_string([], Length, Length) --> [0x00].

value_double(Double) -->
    double(Double).

value_int32(Integer) -->
    int32(Integer).

value_int64(Integer) -->
    int64(Integer).

double(Double) -->
    [B0,B1,B2,B3,B4,B5,B6,B7],
    { bson_bits:bytes_to_float(B0, B1, B2, B3, B4, B5, B6, B7, Double) }.

int32(Integer) -->
    [B0,B1,B2,B3],
    { bson_bits:bytes_to_integer(B0, B1, B2, B3, Integer) }.

int64(Integer) -->
    [B0,B1,B2,B3,B4,B5,B6,B7],
    { bson_bits:bytes_to_integer(B0, B1, B2, B3, B4, B5, B6, B7, Integer) }.

% Fixme, maybe.
%
% A bit of a hack, but in order to interpret raw bytes as UTF-8
% we use a memory file as a temporary buffer, fill it with the
% bytes and then read them back, treating them as UTF-8.
% See: <http://www.swi-prolog.org/pldoc/doc_for?object=memory_file_to_atom/3>

bytes_to_utf8_atom(Bytes, Utf8Atom) :-
    bytes_to_code_points(Bytes, CodePoints),
    builtin:atom_codes(Utf8Atom, CodePoints).

bytes_to_code_points(Bytes, CodePoints) :-
    setup_call_cleanup(
        memory_file:new_memory_file(MemFile),
        bytes_to_memory_file_to_code_points(Bytes, MemFile, CodePoints),
        memory_file:free_memory_file(MemFile)).

bytes_to_memory_file_to_code_points(Bytes, MemFile, CodePoints) :-
    bytes_to_memory_file(Bytes, MemFile),
    memory_file_to_code_points(MemFile, CodePoints).

bytes_to_memory_file(Bytes, MemFile) :-
    setup_call_cleanup(
        open_memory_file_for_putting_bytes(MemFile, PutStream),
        put_bytes(Bytes, PutStream),
        builtin:close(PutStream)).

memory_file_to_code_points(MemFile, CodePoints) :-
    Encoding = utf8,
    memory_file:memory_file_to_codes(MemFile, CodePoints, Encoding).

open_memory_file_for_putting_bytes(MemFile, PutStream) :-
    Options = [encoding(octet)],
    memory_file:open_memory_file(MemFile, write, PutStream, Options).

put_bytes([], _PutStream).
put_bytes([Byte|Bs], PutStream) :-
    builtin:put_byte(PutStream, Byte),
    put_bytes(Bs, PutStream).

/*
% Old (shorter) version using more atom construction. XXX Benchmark.
bytes_to_code_points(Bytes, Utf8Atom) :-
    builtin:atom_chars(RawAtom, Bytes),
    memory_file:atom_to_memory_file(RawAtom, MemFile),
    memory_file:memory_file_to_codes(MemFile, CodePoints, utf8),
    memory_file:free_memory_file(MemFile),
    builtin:atom_codes(Utf8Atom, CodePoints).
*/

length(Length) -->
    int32(Length).

cstring([]) --> [0x00], !.
cstring([Char|Cs]) -->
    [Char], % May not be nul (caught by base case).
    cstring(Cs).

end --> [0x00].
