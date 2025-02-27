module tree_sitter

// This file contains the bindings for C API of tree-sitter.
// They are not indented to be used directly, but rather to be used by the
// wrapper from "tree_sitter.v".
//
// See the header file "./lib/api.h" for comments for functions and structures.

// We directly build "lib.c" rather using the static library.
#flag -I @VMODROOT/core/lib/include
#flag -I @VMODROOT/core/lib/src
#flag @VMODROOT/core/lib/src/lib.c
#include "tree_sitter/api.h"

pub enum TSVInputEncoding {
	utf8
	utf16
}

pub type C.TSInputEncoding = TSVInputEncoding

@[typedef]
pub struct C.TSInput {
mut:
	payload  voidptr
	read     fn (payload voidptr, byte_index u32, position C.TSPoint, bytes_read &u32) &char
	encoding int
}

@[typedef]
pub struct C.TSParser {}

fn C.ts_parser_new() &C.TSParser
fn C.ts_parser_set_language(parser &C.TSParser, language &C.TSLanguage) bool
fn C.ts_parser_parse_string(parser &C.TSParser, const_old_tree &C.TSTree, str &char, len u32) &C.TSTree
fn C.ts_parser_parse(parser &C.TSParser, const_old_tree &C.TSTree, input C.TSInput) &C.TSTree
fn C.ts_parser_delete(tree &C.TSParser)
fn C.ts_parser_reset(parser &C.TSParser)

@[inline]
fn new_ts_parser() &C.TSParser {
	return C.ts_parser_new()
}

@[inline]
fn (mut p C.TSParser) parse(old_tree &TSTree, input C.TSInput) &TSTree {
	return &TSTree(C.ts_parser_parse(p, voidptr(old_tree), input))
}

@[inline]
fn (mut p C.TSParser) reset() {
	C.ts_parser_reset(p)
}

@[inline]
fn (mut p C.TSParser) set_language(language &C.TSLanguage) bool {
	return C.ts_parser_set_language(p, language)
}

@[inline]
fn (mut p C.TSParser) parse_string(content string) &TSTree {
	return p.parse_string_with_old_tree(content, &TSTree(unsafe { nil }))
}

@[inline]
fn (mut p C.TSParser) parse_string_with_old_tree(content string, old_tree &TSTree) &TSTree {
	return p.parse_string_with_old_tree_and_len(content, old_tree, u32(content.len))
}

@[inline]
fn (mut p C.TSParser) parse_string_with_old_tree_and_len(content string, old_tree &TSTree, len u32) &TSTree {
	return &TSTree(C.ts_parser_parse_string(p, voidptr(old_tree), &char(content.str),
		len))
}

@[inline]
fn (mut p C.TSParser) parse_bytes(content []u8) &TSTree {
	return p.parse_bytes_with_old_tree(content, &TSTree(unsafe { nil }))
}

fn byte_array_input_read(pl voidptr, byte_index u32, position C.TSPoint, bytes_read &u32) &char {
	payload := *(&[]u8(pl))
	if byte_index >= u32(payload.len) {
		unsafe {
			*bytes_read = 0
		}
		return c''
	} else {
		unsafe {
			*bytes_read = u32(payload.len) - byte_index
		}
		return unsafe { &char(payload.data) + byte_index }
	}
}

fn (mut p C.TSParser) parse_bytes_with_old_tree(content []u8, old_tree &TSTree) &TSTree {
	return p.parse(old_tree,
		payload: &content
		read: byte_array_input_read
		encoding: int(TSVInputEncoding.utf8)
	)
}

@[inline; unsafe]
fn (p &C.TSParser) free() {
	unsafe {
		C.ts_parser_delete(p)
	}
}

@[typedef]
pub struct C.TSLanguage {}

pub struct C.TSTree {
	included_range_count u32
}

@[export: 'TSTree']
pub struct TSTree {
	included_range_count u32
}

fn C.ts_tree_copy(tree &C.TSTree) &C.TSTree
fn C.ts_tree_root_node(tree &C.TSTree) C.TSNode
fn C.ts_tree_delete(tree &C.TSTree)
fn C.ts_tree_edit(tree &C.TSTree, edit &C.TSInputEdit)
fn C.ts_tree_get_changed_ranges(old_tree &C.TSTree, new_tree &C.TSTree, count &u32) &C.TSRange

@[inline]
fn (tree &TSTree) copy() &TSTree {
	return &TSTree(C.ts_tree_copy(voidptr(tree)))
}

@[inline]
fn (tree &TSTree) root_node() C.TSNode {
	return C.ts_tree_root_node(&C.TSTree(tree))
}

@[inline]
fn (tree &TSTree) edit(input_edit &C.TSInputEdit) {
	C.ts_tree_edit(&C.TSTree(tree), input_edit)
}

fn (tree &TSTree) get_changed_ranges(new_tree &TSTree) []C.TSRange {
	mut len := u32(0)
	buf := C.ts_tree_get_changed_ranges(&C.TSTree(tree), &C.TSTree(new_tree), &len)
	element_size := int(sizeof(C.TSRange))

	return unsafe {
		array{
			element_size: element_size
			len: int(len)
			cap: int(len)
			data: buf
		}
	}
}

@[unsafe]
fn (tree &TSTree) free() {
	unsafe {
		C.ts_tree_delete(&C.TSTree(tree))
	}
}

@[typedef]
pub struct C.TSNode {
	tree &TSTree
}

fn C.ts_node_string(node C.TSNode) &char
fn C.ts_node_type(node C.TSNode) &char
fn C.ts_node_is_null(node C.TSNode) bool
fn C.ts_node_is_named(node C.TSNode) bool
fn C.ts_node_is_missing(node C.TSNode) bool
fn C.ts_node_is_extra(node C.TSNode) bool
fn C.ts_node_has_changes(node C.TSNode) bool
fn C.ts_node_has_error(node C.TSNode) bool

fn C.ts_node_start_point(node C.TSNode) C.TSPoint
fn C.ts_node_end_point(node C.TSNode) C.TSPoint
fn C.ts_node_start_byte(node C.TSNode) u32
fn C.ts_node_end_byte(node C.TSNode) u32

fn C.ts_node_parent(node C.TSNode) C.TSNode
fn C.ts_node_child(node C.TSNode, index u32) C.TSNode
fn C.ts_node_child_count(node C.TSNode) u32
fn C.ts_node_named_child(node C.TSNode, index u32) C.TSNode
fn C.ts_node_named_child_count(node C.TSNode) u32
fn C.ts_node_child_by_field_name(node C.TSNode, field_name &char, field_name_length u32) C.TSNode

fn C.ts_node_next_sibling(node C.TSNode) C.TSNode
fn C.ts_node_prev_sibling(node C.TSNode) C.TSNode
fn C.ts_node_next_named_sibling(node C.TSNode) C.TSNode
fn C.ts_node_prev_named_sibling(node C.TSNode) C.TSNode

fn C.ts_node_first_child_for_byte(node C.TSNode, offset u32) C.TSNode
fn C.ts_node_first_named_child_for_byte(node C.TSNode, offset u32) C.TSNode

fn C.ts_node_descendant_for_byte_range(node C.TSNode, start_offset u32, end_offset u32) C.TSNode
fn C.ts_node_descendant_for_point_range(node C.TSNode, start_point C.TSPoint, end_point C.TSPoint) C.TSNode
fn C.ts_node_named_descendant_for_byte_range(node C.TSNode, start_offset u32, end_offset u32) C.TSNode
fn C.ts_node_named_descendant_for_point_range(node C.TSNode, start_point C.TSPoint, end_point C.TSPoint) C.TSNode

fn C.ts_node_eq(node C.TSNode, another_node C.TSNode) bool

pub fn (node C.TSNode) text(text string) string {
	start_index := node.start_byte()
	end_index := node.end_byte()
	if start_index >= end_index || start_index >= u32(text.len) || end_index > u32(text.len) {
		return ''
	}
	return text.substr(int(start_index), int(end_index))
}

@[inline]
fn (node C.TSNode) sexpr_str() string {
	if node.is_null() {
		return '<null node>'
	}

	sexpr := C.ts_node_string(node)
	return unsafe { sexpr.vstring() }
}

@[inline]
pub fn (node C.TSNode) text_length() u32 {
	start := node.start_byte()
	end := node.end_byte()
	return end - start
}

@[inline]
pub fn (node C.TSNode) start_point() C.TSPoint {
	if node.is_null() {
		return C.TSPoint{0, 0}
	}

	return C.ts_node_start_point(node)
}

fn (node C.TSNode) end_point() C.TSPoint {
	if node.is_null() {
		return C.TSPoint{0, 0}
	}

	return C.ts_node_end_point(node)
}

fn (node C.TSNode) start_byte() u32 {
	if node.is_null() {
		return 0
	}

	return C.ts_node_start_byte(node)
}

fn (node C.TSNode) end_byte() u32 {
	if node.is_null() {
		return 0
	}

	return C.ts_node_end_byte(node)
}

@[inline]
fn (node C.TSNode) range() C.TSRange {
	return C.TSRange{
		start_point: node.start_point()
		end_point: node.end_point()
		start_byte: node.start_byte()
		end_byte: node.end_byte()
	}
}

pub fn (node C.TSNode) type_name() string {
	if node.is_null() {
		return '<null node>'
	}
	c := &char(C.ts_node_type(node))
	return unsafe { c.vstring() }
}

@[inline]
fn (node C.TSNode) is_null() bool {
	return C.ts_node_is_null(node)
}

@[inline]
fn (node C.TSNode) is_named() bool {
	return C.ts_node_is_named(node)
}

@[inline]
fn (node C.TSNode) is_missing() bool {
	return C.ts_node_is_missing(node)
}

@[inline]
fn (node C.TSNode) is_extra() bool {
	return C.ts_node_is_extra(node)
}

@[inline]
fn (node C.TSNode) has_changes() bool {
	return C.ts_node_has_changes(node)
}

fn (node C.TSNode) is_error() bool {
	if node.is_null() {
		return true
	}
	return C.ts_node_has_error(node)
}

pub fn (node C.TSNode) parent_nth(depth int) ?TSNode {
	if node.is_null() {
		return none
	}
	mut res := node
	for _ in 0 .. depth {
		res = res.parent()?
	}
	if res.is_null() {
		return none
	}
	return res
}

pub fn (node C.TSNode) parent() ?C.TSNode {
	if node.is_null() {
		return none
	}
	parent := C.ts_node_parent(node)
	if parent.is_null() {
		return none
	}
	return parent
}

pub fn (node C.TSNode) first_child() ?C.TSNode {
	if node.is_null() {
		return none
	}
	count_child := node.child_count()
	if count_child == 0 {
		return none
	}
	child := C.ts_node_child(node, 0)
	if child.is_null() {
		return none
	}
	return child
}

pub fn (node C.TSNode) last_child() ?C.TSNode {
	if node.is_null() {
		return none
	}
	count_child := node.child_count()
	if count_child == 0 {
		return none
	}
	child := C.ts_node_child(node, count_child - 1)
	if child.is_null() {
		return none
	}
	return child
}

fn (node C.TSNode) child(index u32) ?C.TSNode {
	if node.is_null() {
		return none
	}
	child := C.ts_node_child(node, index)
	if child.is_null() {
		return none
	}
	return child
}

@[inline]
fn (node C.TSNode) child_count() u32 {
	return C.ts_node_child_count(node)
}

fn (node C.TSNode) named_child(pos u32) ?C.TSNode {
	if node.is_null() {
		return none
	}
	child := C.ts_node_named_child(node, pos)
	if child.is_null() {
		return none
	}
	return child
}

fn (node C.TSNode) named_child_count() u32 {
	if node.is_null() {
		return 0
	}
	return C.ts_node_named_child_count(node)
}

pub fn (node C.TSNode) child_by_field_name(name string) ?C.TSNode {
	if node.is_null() {
		return none
	}
	child := C.ts_node_child_by_field_name(node, &char(name.str), u32(name.len))
	if child.is_null() {
		return none
	}

	return child
}

fn (node C.TSNode) next_sibling() ?C.TSNode {
	if node.is_null() {
		return none
	}
	sibling := C.ts_node_next_sibling(node)
	if sibling.is_null() {
		return none
	}
	return sibling
}

fn (node C.TSNode) prev_sibling() ?C.TSNode {
	if node.is_null() {
		return none
	}
	sibling := C.ts_node_prev_sibling(node)
	if sibling.is_null() {
		return none
	}
	return sibling
}

fn (node C.TSNode) next_named_sibling() ?C.TSNode {
	if node.is_null() {
		return none
	}
	sibling := C.ts_node_next_named_sibling(node)
	if sibling.is_null() {
		return none
	}
	return sibling
}

fn (node C.TSNode) prev_named_sibling() ?C.TSNode {
	if node.is_null() {
		return none
	}
	sibling := C.ts_node_prev_named_sibling(node)
	if sibling.is_null() {
		return none
	}
	return sibling
}

fn (node C.TSNode) first_child_for_byte(offset u32) ?C.TSNode {
	if node.is_null() {
		return none
	}
	got_node := C.ts_node_first_child_for_byte(node, offset)
	if got_node.is_null() {
		return none
	}
	return got_node
}

fn (node C.TSNode) first_named_child_for_byte(offset u32) ?C.TSNode {
	if node.is_null() {
		return none
	}
	got_node := C.ts_node_first_named_child_for_byte(node, offset)
	if got_node.is_null() {
		return none
	}
	return got_node
}

fn (node C.TSNode) descendant_for_byte_range(start_range u32, end_range u32) ?C.TSNode {
	if node.is_null() {
		return none
	}
	got_node := C.ts_node_descendant_for_byte_range(node, start_range, end_range)
	if got_node.is_null() {
		return none
	}
	return got_node
}

fn (node C.TSNode) descendant_for_point_range(start_point C.TSPoint, end_point C.TSPoint) ?C.TSNode {
	if node.is_null() {
		return none
	}
	got_node := C.ts_node_descendant_for_point_range(node, start_point, end_point)
	if got_node.is_null() {
		return none
	}
	return got_node
}

fn (node C.TSNode) named_descendant_for_byte_range(start_range u32, end_range u32) ?C.TSNode {
	if node.is_null() {
		return none
	}
	got_node := C.ts_node_named_descendant_for_byte_range(node, start_range, end_range)
	if got_node.is_null() {
		return none
	}
	return got_node
}

fn (node C.TSNode) named_descendant_for_point_range(start_point C.TSPoint, end_point C.TSPoint) ?C.TSNode {
	if node.is_null() {
		return none
	}
	got_node := C.ts_node_named_descendant_for_point_range(node, start_point, end_point)
	if got_node.is_null() {
		return none
	}
	return got_node
}

fn C.ts_tree_cursor_new(node C.TSNode) C.TSTreeCursor

pub type TSTreeCursor = C.TSTreeCursor

@[inline]
pub fn (node C.TSNode) tree_cursor() TSTreeCursor {
	return C.ts_tree_cursor_new(node)
}

@[typedef]
pub struct C.TSTreeCursor {
	tree    voidptr
	id      voidptr
	context [2]u32
}

fn C.ts_tree_cursor_delete(cursor &C.TSTreeCursor)
fn C.ts_tree_cursor_reset(cursor &C.TSTreeCursor, node C.TSNode)
fn C.ts_tree_cursor_current_node(cursor &C.TSTreeCursor) C.TSNode
fn C.ts_tree_cursor_current_field_name(cursor &C.TSTreeCursor) &char
fn C.ts_tree_cursor_goto_parent(cursor &C.TSTreeCursor) bool
fn C.ts_tree_cursor_goto_next_sibling(cursor &C.TSTreeCursor) bool
fn C.ts_tree_cursor_goto_first_child(cursor &C.TSTreeCursor) bool
fn C.ts_tree_cursor_first_child_for_byte(cursor &C.TSTreeCursor, idx u32) i64
fn C.ts_tree_cursor_copy(cursor &C.TSTreeCursor) C.TSTreeCursor

@[inline; unsafe]
fn (cursor &C.TSTreeCursor) free() {
	C.ts_tree_cursor_delete(cursor)
}

@[inline]
fn (mut cursor C.TSTreeCursor) reset(node C.TSNode) {
	C.ts_tree_cursor_reset(cursor, node)
}

pub type TSNode = C.TSNode

@[inline]
pub fn (cursor &C.TSTreeCursor) current_node() ?TSNode {
	got_node := C.ts_tree_cursor_current_node(cursor)
	if got_node.is_null() {
		return none
	}
	return got_node
}

@[inline]
pub fn (cursor &C.TSTreeCursor) current_field_name() string {
	c := &char(C.ts_tree_cursor_current_field_name(cursor))
	return unsafe { c.vstring() }
}

@[inline]
pub fn (mut cursor C.TSTreeCursor) to_parent() bool {
	return C.ts_tree_cursor_goto_parent(cursor)
}

@[inline]
pub fn (mut cursor C.TSTreeCursor) next() bool {
	return C.ts_tree_cursor_goto_next_sibling(cursor)
}

@[inline]
pub fn (mut cursor C.TSTreeCursor) to_first_child() bool {
	return C.ts_tree_cursor_goto_first_child(cursor)
}

@[typedef]
pub struct C.TSInputEdit {
	start_byte    u32
	old_end_byte  u32
	new_end_byte  u32
	start_point   C.TSPoint
	old_end_point C.TSPoint
	new_end_point C.TSPoint
}

@[typedef]
pub struct C.TSPoint {
pub:
	row    u32
	column u32
}

fn (left_point C.TSPoint) eq(right_point C.TSPoint) bool {
	return left_point.row == right_point.row && left_point.column == right_point.column
}

@[typedef]
pub struct C.TSRange {
pub:
	start_point C.TSPoint
	end_point   C.TSPoint
	start_byte  u32
	end_byte    u32
}

fn (left_range C.TSRange) eq(right_range C.TSRange) bool {
	return left_range.start_point.eq(right_range.start_point)
		&& left_range.end_point.eq(right_range.end_point)
		&& left_range.start_byte == right_range.start_byte
		&& left_range.end_byte == right_range.end_byte
}
