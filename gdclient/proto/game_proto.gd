#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		if data_type == PB_DATA_TYPE.FLOAT:
			return bytes.decode_float(index)
		elif data_type == PB_DATA_TYPE.DOUBLE:
			return bytes.decode_double(index)
		else:
			# Convert to big endian
			var slice: PackedByteArray = bytes.slice(index, index + count)
			slice.reverse()
			return slice

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		var i: int = varint_bytes.size() - 1
		while i > -1:
			value = (value << 7) | (varint_bytes[i] & 0x7F)
			i -= 1
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var i: int = index
		while i <= index + 10: # Protobuf varint max size is 10 bytes
			if !(bytes[i] & 0x80):
				return bytes.slice(index, i + 1)
			i += 1
		return [] # Unreachable

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func skip_unknown_field(bytes : PackedByteArray, offset : int, type : int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes : PackedByteArray = isolate_varint(bytes, offset)
			var length : int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
				else:
					var res : int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
						offset = res
						if offset == limit:
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break							
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class Card:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__description = PBField.new("description", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __description
		data[__description.tag] = service
		
		__image = PBField.new("image", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __image
		data[__image.tag] = service
		
		__rarity = PBField.new("rarity", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __rarity
		data[__rarity.tag] = service
		
		__spell_class = PBField.new("spell_class", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __spell_class
		data[__spell_class.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __description: PBField
	func has_description() -> bool:
		if __description.value != null:
			return true
		return false
	func get_description() -> String:
		return __description.value
	func clear_description() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__description.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_description(value : String) -> void:
		__description.value = value
	
	var __image: PBField
	func has_image() -> bool:
		if __image.value != null:
			return true
		return false
	func get_image() -> String:
		return __image.value
	func clear_image() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__image.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_image(value : String) -> void:
		__image.value = value
	
	var __rarity: PBField
	func has_rarity() -> bool:
		if __rarity.value != null:
			return true
		return false
	func get_rarity() -> int:
		return __rarity.value
	func clear_rarity() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__rarity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_rarity(value : int) -> void:
		__rarity.value = value
	
	var __spell_class: PBField
	func has_spell_class() -> bool:
		if __spell_class.value != null:
			return true
		return false
	func get_spell_class() -> int:
		return __spell_class.value
	func clear_spell_class() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__spell_class.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_spell_class(value : int) -> void:
		__spell_class.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class WordCard:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__word = PBField.new("word", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __word
		data[__word.tag] = service
		
		__word_class = PBField.new("word_class", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __word_class
		data[__word_class.tag] = service
		
		__description = PBField.new("description", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __description
		data[__description.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __word: PBField
	func has_word() -> bool:
		if __word.value != null:
			return true
		return false
	func get_word() -> String:
		return __word.value
	func clear_word() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__word.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_word(value : String) -> void:
		__word.value = value
	
	var __word_class: PBField
	func has_word_class() -> bool:
		if __word_class.value != null:
			return true
		return false
	func get_word_class() -> String:
		return __word_class.value
	func clear_word_class() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__word_class.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_word_class(value : String) -> void:
		__word_class.value = value
	
	var __description: PBField
	func has_description() -> bool:
		if __description.value != null:
			return true
		return false
	func get_description() -> String:
		return __description.value
	func clear_description() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__description.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_description(value : String) -> void:
		__description.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CardTable:
	func _init():
		var service
		
		var __cards_default: Array[WordCard] = []
		__cards = PBField.new("cards", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __cards_default)
		service = PBServiceField.new()
		service.field = __cards
		service.func_ref = Callable(self, "add_cards")
		data[__cards.tag] = service
		
		__sentence = PBField.new("sentence", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __sentence
		data[__sentence.tag] = service
		
	var data = {}
	
	var __cards: PBField
	func get_cards() -> Array[WordCard]:
		return __cards.value
	func clear_cards() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__cards.value.clear()
	func add_cards() -> WordCard:
		var element = WordCard.new()
		__cards.value.append(element)
		return element
	
	var __sentence: PBField
	func has_sentence() -> bool:
		if __sentence.value != null:
			return true
		return false
	func get_sentence() -> String:
		return __sentence.value
	func clear_sentence() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__sentence.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sentence(value : String) -> void:
		__sentence.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BattlePlayer:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		var __cards_default: Array[WordCard] = []
		__cards = PBField.new("cards", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, __cards_default)
		service = PBServiceField.new()
		service.field = __cards
		service.func_ref = Callable(self, "add_cards")
		data[__cards.tag] = service
		
		__current_score = PBField.new("current_score", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __current_score
		data[__current_score.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __cards: PBField
	func get_cards() -> Array[WordCard]:
		return __cards.value
	func clear_cards() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__cards.value.clear()
	func add_cards() -> WordCard:
		var element = WordCard.new()
		__cards.value.append(element)
		return element
	
	var __current_score: PBField
	func has_current_score() -> bool:
		if __current_score.value != null:
			return true
		return false
	func get_current_score() -> int:
		return __current_score.value
	func clear_current_score() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__current_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_score(value : int) -> void:
		__current_score.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum ActionType {
	ACTION_UNKNOWN = 0,
	PLACE_CARD = 1,
	SKIP_TURN = 2,
	AUTO_CHAT = 3,
	SURRENDER = 4,
	CHAR_MOVE = 5
}

class CharacterMoveAction:
	func _init():
		var service
		
		__from_x = PBField.new("from_x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __from_x
		data[__from_x.tag] = service
		
		__from_y = PBField.new("from_y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __from_y
		data[__from_y.tag] = service
		
		__to_x = PBField.new("to_x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __to_x
		data[__to_x.tag] = service
		
		__to_y = PBField.new("to_y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __to_y
		data[__to_y.tag] = service
		
	var data = {}
	
	var __from_x: PBField
	func has_from_x() -> bool:
		if __from_x.value != null:
			return true
		return false
	func get_from_x() -> int:
		return __from_x.value
	func clear_from_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__from_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_from_x(value : int) -> void:
		__from_x.value = value
	
	var __from_y: PBField
	func has_from_y() -> bool:
		if __from_y.value != null:
			return true
		return false
	func get_from_y() -> int:
		return __from_y.value
	func clear_from_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__from_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_from_y(value : int) -> void:
		__from_y.value = value
	
	var __to_x: PBField
	func has_to_x() -> bool:
		if __to_x.value != null:
			return true
		return false
	func get_to_x() -> int:
		return __to_x.value
	func clear_to_x() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__to_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_to_x(value : int) -> void:
		__to_x.value = value
	
	var __to_y: PBField
	func has_to_y() -> bool:
		if __to_y.value != null:
			return true
		return false
	func get_to_y() -> int:
		return __to_y.value
	func clear_to_y() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__to_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_to_y(value : int) -> void:
		__to_y.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlaceCardAction:
	func _init():
		var service
		
		__card_id = PBField.new("card_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __card_id
		data[__card_id.tag] = service
		
		__target_index = PBField.new("target_index", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __target_index
		data[__target_index.tag] = service
		
	var data = {}
	
	var __card_id: PBField
	func has_card_id() -> bool:
		if __card_id.value != null:
			return true
		return false
	func get_card_id() -> int:
		return __card_id.value
	func clear_card_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__card_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_card_id(value : int) -> void:
		__card_id.value = value
	
	var __target_index: PBField
	func has_target_index() -> bool:
		if __target_index.value != null:
			return true
		return false
	func get_target_index() -> int:
		return __target_index.value
	func clear_target_index() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__target_index.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_target_index(value : int) -> void:
		__target_index.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameAction:
	func _init():
		var service
		
		__player_id = PBField.new("player_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __player_id
		data[__player_id.tag] = service
		
		__action_type = PBField.new("action_type", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __action_type
		data[__action_type.tag] = service
		
		__timestamp = PBField.new("timestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __timestamp
		data[__timestamp.tag] = service
		
		__place_card = PBField.new("place_card", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __place_card
		service.func_ref = Callable(self, "new_place_card")
		data[__place_card.tag] = service
		
		__char_move = PBField.new("char_move", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __char_move
		service.func_ref = Callable(self, "new_char_move")
		data[__char_move.tag] = service
		
	var data = {}
	
	var __player_id: PBField
	func has_player_id() -> bool:
		if __player_id.value != null:
			return true
		return false
	func get_player_id() -> int:
		return __player_id.value
	func clear_player_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__player_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_player_id(value : int) -> void:
		__player_id.value = value
	
	var __action_type: PBField
	func has_action_type() -> bool:
		if __action_type.value != null:
			return true
		return false
	func get_action_type():
		return __action_type.value
	func clear_action_type() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__action_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_action_type(value) -> void:
		__action_type.value = value
	
	var __timestamp: PBField
	func has_timestamp() -> bool:
		if __timestamp.value != null:
			return true
		return false
	func get_timestamp() -> int:
		return __timestamp.value
	func clear_timestamp() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value : int) -> void:
		__timestamp.value = value
	
	var __place_card: PBField
	func has_place_card() -> bool:
		if __place_card.value != null:
			return true
		return false
	func get_place_card() -> PlaceCardAction:
		return __place_card.value
	func clear_place_card() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__place_card.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_place_card() -> PlaceCardAction:
		data[4].state = PB_SERVICE_STATE.FILLED
		__char_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__place_card.value = PlaceCardAction.new()
		return __place_card.value
	
	var __char_move: PBField
	func has_char_move() -> bool:
		if __char_move.value != null:
			return true
		return false
	func get_char_move() -> CharacterMoveAction:
		return __char_move.value
	func clear_char_move() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__char_move.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_char_move() -> CharacterMoveAction:
		__place_card.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		data[5].state = PB_SERVICE_STATE.FILLED
		__char_move.value = CharacterMoveAction.new()
		return __char_move.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum ActionResult {
	SUCCESS = 0,
	ERROR_INVALID_TARGET = 1,
	ERROR_CARD_NOT_FOUND = 2,
	ERROR_NOT_YOUR_TURN = 3,
	ERROR_UNKNOWN = 4
}

class ActionResponse:
	func _init():
		var service
		
		__result = PBField.new("result", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __result
		data[__result.tag] = service
		
		__server_time = PBField.new("server_time", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __server_time
		data[__server_time.tag] = service
		
		__state = PBField.new("state", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __state
		service.func_ref = Callable(self, "new_state")
		data[__state.tag] = service
		
	var data = {}
	
	var __result: PBField
	func has_result() -> bool:
		if __result.value != null:
			return true
		return false
	func get_result():
		return __result.value
	func clear_result() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__result.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_result(value) -> void:
		__result.value = value
	
	var __server_time: PBField
	func has_server_time() -> bool:
		if __server_time.value != null:
			return true
		return false
	func get_server_time() -> int:
		return __server_time.value
	func clear_server_time() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__server_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_server_time(value : int) -> void:
		__server_time.value = value
	
	var __state: PBField
	func has_state() -> bool:
		if __state.value != null:
			return true
		return false
	func get_state() -> GameState:
		return __state.value
	func clear_state() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_state() -> GameState:
		__state.value = GameState.new()
		return __state.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameState:
	func _init():
		var service
		
		var __players_default: Array[BattlePlayer] = []
		__players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __players_default)
		service = PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
		__card_table = PBField.new("card_table", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __card_table
		service.func_ref = Callable(self, "new_card_table")
		data[__card_table.tag] = service
		
		__current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __current_turn
		data[__current_turn.tag] = service
		
	var data = {}
	
	var __players: PBField
	func get_players() -> Array[BattlePlayer]:
		return __players.value
	func clear_players() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__players.value.clear()
	func add_players() -> BattlePlayer:
		var element = BattlePlayer.new()
		__players.value.append(element)
		return element
	
	var __card_table: PBField
	func has_card_table() -> bool:
		if __card_table.value != null:
			return true
		return false
	func get_card_table() -> CardTable:
		return __card_table.value
	func clear_card_table() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__card_table.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_card_table() -> CardTable:
		__card_table.value = CardTable.new()
		return __card_table.value
	
	var __current_turn: PBField
	func has_current_turn() -> bool:
		if __current_turn.value != null:
			return true
		return false
	func get_current_turn() -> int:
		return __current_turn.value
	func clear_current_turn() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		__current_turn.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameStateNotify:
	func _init():
		var service
		
		__be_notified_uid = PBField.new("be_notified_uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __be_notified_uid
		data[__be_notified_uid.tag] = service
		
		__room_id = PBField.new("room_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __room_id
		data[__room_id.tag] = service
		
		__game_state = PBField.new("game_state", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __game_state
		service.func_ref = Callable(self, "new_game_state")
		data[__game_state.tag] = service
		
	var data = {}
	
	var __be_notified_uid: PBField
	func has_be_notified_uid() -> bool:
		if __be_notified_uid.value != null:
			return true
		return false
	func get_be_notified_uid() -> int:
		return __be_notified_uid.value
	func clear_be_notified_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__be_notified_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_be_notified_uid(value : int) -> void:
		__be_notified_uid.value = value
	
	var __room_id: PBField
	func has_room_id() -> bool:
		if __room_id.value != null:
			return true
		return false
	func get_room_id() -> String:
		return __room_id.value
	func clear_room_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__room_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_room_id(value : String) -> void:
		__room_id.value = value
	
	var __game_state: PBField
	func has_game_state() -> bool:
		if __game_state.value != null:
			return true
		return false
	func get_game_state() -> GameState:
		return __game_state.value
	func clear_game_state() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__game_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_game_state() -> GameState:
		__game_state.value = GameState.new()
		return __game_state.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerActionNotify:
	func _init():
		var service
		
		__be_notified_uid = PBField.new("be_notified_uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __be_notified_uid
		data[__be_notified_uid.tag] = service
		
		__room_id = PBField.new("room_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __room_id
		data[__room_id.tag] = service
		
		__player_id = PBField.new("player_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __player_id
		data[__player_id.tag] = service
		
		__action = PBField.new("action", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __action
		service.func_ref = Callable(self, "new_action")
		data[__action.tag] = service
		
	var data = {}
	
	var __be_notified_uid: PBField
	func has_be_notified_uid() -> bool:
		if __be_notified_uid.value != null:
			return true
		return false
	func get_be_notified_uid() -> int:
		return __be_notified_uid.value
	func clear_be_notified_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__be_notified_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_be_notified_uid(value : int) -> void:
		__be_notified_uid.value = value
	
	var __room_id: PBField
	func has_room_id() -> bool:
		if __room_id.value != null:
			return true
		return false
	func get_room_id() -> String:
		return __room_id.value
	func clear_room_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__room_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_room_id(value : String) -> void:
		__room_id.value = value
	
	var __player_id: PBField
	func has_player_id() -> bool:
		if __player_id.value != null:
			return true
		return false
	func get_player_id() -> int:
		return __player_id.value
	func clear_player_id() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__player_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_player_id(value : int) -> void:
		__player_id.value = value
	
	var __action: PBField
	func has_action() -> bool:
		if __action.value != null:
			return true
		return false
	func get_action() -> GameAction:
		return __action.value
	func clear_action() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__action.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_action() -> GameAction:
		__action.value = GameAction.new()
		return __action.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NotifyResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret() -> int:
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ret(value : int) -> void:
		__ret.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RoomPlayer:
	func _init():
		var service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__position_x = PBField.new("position_x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __position_x
		data[__position_x.tag] = service
		
		__position_y = PBField.new("position_y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __position_y
		data[__position_y.tag] = service
		
	var data = {}
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __position_x: PBField
	func has_position_x() -> bool:
		if __position_x.value != null:
			return true
		return false
	func get_position_x() -> int:
		return __position_x.value
	func clear_position_x() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__position_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_position_x(value : int) -> void:
		__position_x.value = value
	
	var __position_y: PBField
	func has_position_y() -> bool:
		if __position_y.value != null:
			return true
		return false
	func get_position_y() -> int:
		return __position_y.value
	func clear_position_y() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__position_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_position_y(value : int) -> void:
		__position_y.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Room:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__max_players = PBField.new("max_players", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __max_players
		data[__max_players.tag] = service
		
		__current_players = PBField.new("current_players", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __current_players
		data[__current_players.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __max_players: PBField
	func has_max_players() -> bool:
		if __max_players.value != null:
			return true
		return false
	func get_max_players() -> int:
		return __max_players.value
	func clear_max_players() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__max_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_max_players(value : int) -> void:
		__max_players.value = value
	
	var __current_players: PBField
	func has_current_players() -> bool:
		if __current_players.value != null:
			return true
		return false
	func get_current_players() -> int:
		return __current_players.value
	func clear_current_players() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__current_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_players(value : int) -> void:
		__current_players.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RoomDetail:
	func _init():
		var service
		
		__room = PBField.new("room", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __room
		service.func_ref = Callable(self, "new_room")
		data[__room.tag] = service
		
		var __current_players_default: Array[RoomPlayer] = []
		__current_players = PBField.new("current_players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __current_players_default)
		service = PBServiceField.new()
		service.field = __current_players
		service.func_ref = Callable(self, "add_current_players")
		data[__current_players.tag] = service
		
	var data = {}
	
	var __room: PBField
	func has_room() -> bool:
		if __room.value != null:
			return true
		return false
	func get_room() -> Room:
		return __room.value
	func clear_room() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__room.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_room() -> Room:
		__room.value = Room.new()
		return __room.value
	
	var __current_players: PBField
	func get_current_players() -> Array[RoomPlayer]:
		return __current_players.value
	func clear_current_players() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__current_players.value.clear()
	func add_current_players() -> RoomPlayer:
		var element = RoomPlayer.new()
		__current_players.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AuthRequest:
	func _init():
		var service
		
		__token = PBField.new("token", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __token
		data[__token.tag] = service
		
		__protocol_version = PBField.new("protocol_version", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __protocol_version
		data[__protocol_version.tag] = service
		
		__client_version = PBField.new("client_version", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __client_version
		data[__client_version.tag] = service
		
		__device_type = PBField.new("device_type", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __device_type
		data[__device_type.tag] = service
		
		__device_id = PBField.new("device_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __device_id
		data[__device_id.tag] = service
		
		__app_id = PBField.new("app_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __app_id
		data[__app_id.tag] = service
		
		__nonce = PBField.new("nonce", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __nonce
		data[__nonce.tag] = service
		
		__timestamp = PBField.new("timestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __timestamp
		data[__timestamp.tag] = service
		
		__signature = PBField.new("signature", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __signature
		data[__signature.tag] = service
		
		__is_guest = PBField.new("is_guest", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __is_guest
		data[__is_guest.tag] = service
		
	var data = {}
	
	var __token: PBField
	func has_token() -> bool:
		if __token.value != null:
			return true
		return false
	func get_token() -> String:
		return __token.value
	func clear_token() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__token.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_token(value : String) -> void:
		__token.value = value
	
	var __protocol_version: PBField
	func has_protocol_version() -> bool:
		if __protocol_version.value != null:
			return true
		return false
	func get_protocol_version() -> String:
		return __protocol_version.value
	func clear_protocol_version() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__protocol_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_protocol_version(value : String) -> void:
		__protocol_version.value = value
	
	var __client_version: PBField
	func has_client_version() -> bool:
		if __client_version.value != null:
			return true
		return false
	func get_client_version() -> String:
		return __client_version.value
	func clear_client_version() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__client_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_client_version(value : String) -> void:
		__client_version.value = value
	
	var __device_type: PBField
	func has_device_type() -> bool:
		if __device_type.value != null:
			return true
		return false
	func get_device_type() -> String:
		return __device_type.value
	func clear_device_type() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__device_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_device_type(value : String) -> void:
		__device_type.value = value
	
	var __device_id: PBField
	func has_device_id() -> bool:
		if __device_id.value != null:
			return true
		return false
	func get_device_id() -> String:
		return __device_id.value
	func clear_device_id() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__device_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_device_id(value : String) -> void:
		__device_id.value = value
	
	var __app_id: PBField
	func has_app_id() -> bool:
		if __app_id.value != null:
			return true
		return false
	func get_app_id() -> String:
		return __app_id.value
	func clear_app_id() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__app_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_app_id(value : String) -> void:
		__app_id.value = value
	
	var __nonce: PBField
	func has_nonce() -> bool:
		if __nonce.value != null:
			return true
		return false
	func get_nonce() -> String:
		return __nonce.value
	func clear_nonce() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__nonce.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_nonce(value : String) -> void:
		__nonce.value = value
	
	var __timestamp: PBField
	func has_timestamp() -> bool:
		if __timestamp.value != null:
			return true
		return false
	func get_timestamp() -> int:
		return __timestamp.value
	func clear_timestamp() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value : int) -> void:
		__timestamp.value = value
	
	var __signature: PBField
	func has_signature() -> bool:
		if __signature.value != null:
			return true
		return false
	func get_signature() -> String:
		return __signature.value
	func clear_signature() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__signature.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_signature(value : String) -> void:
		__signature.value = value
	
	var __is_guest: PBField
	func has_is_guest() -> bool:
		if __is_guest.value != null:
			return true
		return false
	func get_is_guest() -> bool:
		return __is_guest.value
	func clear_is_guest() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__is_guest.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_guest(value : bool) -> void:
		__is_guest.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AuthResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
		__conn_id = PBField.new("conn_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __conn_id
		data[__conn_id.tag] = service
		
		__server_time = PBField.new("server_time", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __server_time
		data[__server_time.tag] = service
		
		__session_expiry = PBField.new("session_expiry", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __session_expiry
		data[__session_expiry.tag] = service
		
		__nickname = PBField.new("nickname", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __nickname
		data[__nickname.tag] = service
		
		__level = PBField.new("level", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __level
		data[__level.tag] = service
		
		__exp = PBField.new("exp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __exp
		data[__exp.tag] = service
		
		__gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __gold
		data[__gold.tag] = service
		
		__diamond = PBField.new("diamond", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __diamond
		data[__diamond.tag] = service
		
		__error_msg = PBField.new("error_msg", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __error_msg
		data[__error_msg.tag] = service
		
		__is_guest = PBField.new("is_guest", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __is_guest
		data[__is_guest.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	var __conn_id: PBField
	func has_conn_id() -> bool:
		if __conn_id.value != null:
			return true
		return false
	func get_conn_id() -> String:
		return __conn_id.value
	func clear_conn_id() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__conn_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_conn_id(value : String) -> void:
		__conn_id.value = value
	
	var __server_time: PBField
	func has_server_time() -> bool:
		if __server_time.value != null:
			return true
		return false
	func get_server_time() -> String:
		return __server_time.value
	func clear_server_time() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__server_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_server_time(value : String) -> void:
		__server_time.value = value
	
	var __session_expiry: PBField
	func has_session_expiry() -> bool:
		if __session_expiry.value != null:
			return true
		return false
	func get_session_expiry() -> int:
		return __session_expiry.value
	func clear_session_expiry() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__session_expiry.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_session_expiry(value : int) -> void:
		__session_expiry.value = value
	
	var __nickname: PBField
	func has_nickname() -> bool:
		if __nickname.value != null:
			return true
		return false
	func get_nickname() -> String:
		return __nickname.value
	func clear_nickname() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__nickname.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_nickname(value : String) -> void:
		__nickname.value = value
	
	var __level: PBField
	func has_level() -> bool:
		if __level.value != null:
			return true
		return false
	func get_level() -> int:
		return __level.value
	func clear_level() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__level.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_level(value : int) -> void:
		__level.value = value
	
	var __exp: PBField
	func has_exp() -> bool:
		if __exp.value != null:
			return true
		return false
	func get_exp() -> int:
		return __exp.value
	func clear_exp() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__exp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_exp(value : int) -> void:
		__exp.value = value
	
	var __gold: PBField
	func has_gold() -> bool:
		if __gold.value != null:
			return true
		return false
	func get_gold() -> int:
		return __gold.value
	func clear_gold() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		__gold.value = value
	
	var __diamond: PBField
	func has_diamond() -> bool:
		if __diamond.value != null:
			return true
		return false
	func get_diamond() -> int:
		return __diamond.value
	func clear_diamond() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__diamond.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_diamond(value : int) -> void:
		__diamond.value = value
	
	var __error_msg: PBField
	func has_error_msg() -> bool:
		if __error_msg.value != null:
			return true
		return false
	func get_error_msg() -> String:
		return __error_msg.value
	func clear_error_msg() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__error_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_error_msg(value : String) -> void:
		__error_msg.value = value
	
	var __is_guest: PBField
	func has_is_guest() -> bool:
		if __is_guest.value != null:
			return true
		return false
	func get_is_guest() -> bool:
		return __is_guest.value
	func clear_is_guest() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__is_guest.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_guest(value : bool) -> void:
		__is_guest.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetRoomListRequest:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetRoomListResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		var __rooms_default: Array[Room] = []
		__rooms = PBField.new("rooms", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __rooms_default)
		service = PBServiceField.new()
		service.field = __rooms
		service.func_ref = Callable(self, "add_rooms")
		data[__rooms.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __rooms: PBField
	func get_rooms() -> Array[Room]:
		return __rooms.value
	func clear_rooms() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__rooms.value.clear()
	func add_rooms() -> Room:
		var element = Room.new()
		__rooms.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CreateRoomRequest:
	func _init():
		var service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
	var data = {}
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CreateRoomResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__room_detail = PBField.new("room_detail", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __room_detail
		service.func_ref = Callable(self, "new_room_detail")
		data[__room_detail.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __room_detail: PBField
	func has_room_detail() -> bool:
		if __room_detail.value != null:
			return true
		return false
	func get_room_detail() -> RoomDetail:
		return __room_detail.value
	func clear_room_detail() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__room_detail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_room_detail() -> RoomDetail:
		__room_detail.value = RoomDetail.new()
		return __room_detail.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinRoomRequest:
	func _init():
		var service
		
		__roomId = PBField.new("roomId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __roomId
		data[__roomId.tag] = service
		
	var data = {}
	
	var __roomId: PBField
	func has_roomId() -> bool:
		if __roomId.value != null:
			return true
		return false
	func get_roomId() -> String:
		return __roomId.value
	func clear_roomId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__roomId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_roomId(value : String) -> void:
		__roomId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinRoomResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__room_detail = PBField.new("room_detail", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __room_detail
		service.func_ref = Callable(self, "new_room_detail")
		data[__room_detail.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __room_detail: PBField
	func has_room_detail() -> bool:
		if __room_detail.value != null:
			return true
		return false
	func get_room_detail() -> RoomDetail:
		return __room_detail.value
	func clear_room_detail() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__room_detail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_room_detail() -> RoomDetail:
		__room_detail.value = RoomDetail.new()
		return __room_detail.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LeaveRoomRequest:
	func _init():
		var service
		
		__playerId = PBField.new("playerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __playerId
		data[__playerId.tag] = service
		
	var data = {}
	
	var __playerId: PBField
	func has_playerId() -> bool:
		if __playerId.value != null:
			return true
		return false
	func get_playerId() -> String:
		return __playerId.value
	func clear_playerId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_playerId(value : String) -> void:
		__playerId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LeaveRoomResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__room = PBField.new("room", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __room
		service.func_ref = Callable(self, "new_room")
		data[__room.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __room: PBField
	func has_room() -> bool:
		if __room.value != null:
			return true
		return false
	func get_room() -> Room:
		return __room.value
	func clear_room() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__room.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_room() -> Room:
		__room.value = Room.new()
		return __room.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetReadyRequest:
	func _init():
		var service
		
		__playerId = PBField.new("playerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __playerId
		data[__playerId.tag] = service
		
	var data = {}
	
	var __playerId: PBField
	func has_playerId() -> bool:
		if __playerId.value != null:
			return true
		return false
	func get_playerId() -> String:
		return __playerId.value
	func clear_playerId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_playerId(value : String) -> void:
		__playerId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetReadyResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BackpackInfo:
	func _init():
		var service
		
		var __cards_default: Array[Card] = []
		__cards = PBField.new("cards", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __cards_default)
		service = PBServiceField.new()
		service.field = __cards
		service.func_ref = Callable(self, "add_cards")
		data[__cards.tag] = service
		
	var data = {}
	
	var __cards: PBField
	func get_cards() -> Array[Card]:
		return __cards.value
	func clear_cards() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__cards.value.clear()
	func add_cards() -> Card:
		var element = Card.new()
		__cards.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UserInfo:
	func _init():
		var service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__exp = PBField.new("exp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __exp
		data[__exp.tag] = service
		
		__gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __gold
		data[__gold.tag] = service
		
		__diamond = PBField.new("diamond", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __diamond
		data[__diamond.tag] = service
		
		__draw_card_count = PBField.new("draw_card_count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __draw_card_count
		data[__draw_card_count.tag] = service
		
		__backpack = PBField.new("backpack", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __backpack
		service.func_ref = Callable(self, "new_backpack")
		data[__backpack.tag] = service
		
	var data = {}
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __exp: PBField
	func has_exp() -> bool:
		if __exp.value != null:
			return true
		return false
	func get_exp() -> int:
		return __exp.value
	func clear_exp() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__exp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_exp(value : int) -> void:
		__exp.value = value
	
	var __gold: PBField
	func has_gold() -> bool:
		if __gold.value != null:
			return true
		return false
	func get_gold() -> int:
		return __gold.value
	func clear_gold() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		__gold.value = value
	
	var __diamond: PBField
	func has_diamond() -> bool:
		if __diamond.value != null:
			return true
		return false
	func get_diamond() -> int:
		return __diamond.value
	func clear_diamond() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__diamond.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_diamond(value : int) -> void:
		__diamond.value = value
	
	var __draw_card_count: PBField
	func has_draw_card_count() -> bool:
		if __draw_card_count.value != null:
			return true
		return false
	func get_draw_card_count() -> int:
		return __draw_card_count.value
	func clear_draw_card_count() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__draw_card_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_draw_card_count(value : int) -> void:
		__draw_card_count.value = value
	
	var __backpack: PBField
	func has_backpack() -> bool:
		if __backpack.value != null:
			return true
		return false
	func get_backpack() -> BackpackInfo:
		return __backpack.value
	func clear_backpack() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__backpack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_backpack() -> BackpackInfo:
		__backpack.value = BackpackInfo.new()
		return __backpack.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetUserInfoRequest:
	func _init():
		var service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
	var data = {}
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetUserInfoResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__user_info = PBField.new("user_info", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __user_info
		service.func_ref = Callable(self, "new_user_info")
		data[__user_info.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __user_info: PBField
	func has_user_info() -> bool:
		if __user_info.value != null:
			return true
		return false
	func get_user_info() -> UserInfo:
		return __user_info.value
	func clear_user_info() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__user_info.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_user_info() -> UserInfo:
		__user_info.value = UserInfo.new()
		return __user_info.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DrawCardRequest:
	func _init():
		var service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	var __count: PBField
	func has_count() -> bool:
		if __count.value != null:
			return true
		return false
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DrawCardResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		var __cards_default: Array[Card] = []
		__cards = PBField.new("cards", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __cards_default)
		service = PBServiceField.new()
		service.field = __cards
		service.func_ref = Callable(self, "add_cards")
		data[__cards.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __cards: PBField
	func get_cards() -> Array[Card]:
		return __cards.value
	func clear_cards() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__cards.value.clear()
	func add_cards() -> Card:
		var element = Card.new()
		__cards.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class StartGameBattleRequest:
	func _init():
		var service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
	var data = {}
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class StartGameBattleResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__battle_id = PBField.new("battle_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __battle_id
		data[__battle_id.tag] = service
		
		__battle_server_addr = PBField.new("battle_server_addr", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __battle_server_addr
		data[__battle_server_addr.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __battle_id: PBField
	func has_battle_id() -> bool:
		if __battle_id.value != null:
			return true
		return false
	func get_battle_id() -> String:
		return __battle_id.value
	func clear_battle_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__battle_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_battle_id(value : String) -> void:
		__battle_id.value = value
	
	var __battle_server_addr: PBField
	func has_battle_server_addr() -> bool:
		if __battle_server_addr.value != null:
			return true
		return false
	func get_battle_server_addr() -> String:
		return __battle_server_addr.value
	func clear_battle_server_addr() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__battle_server_addr.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_battle_server_addr(value : String) -> void:
		__battle_server_addr.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameActionRequest:
	func _init():
		var service
		
		__action = PBField.new("action", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __action
		service.func_ref = Callable(self, "new_action")
		data[__action.tag] = service
		
	var data = {}
	
	var __action: PBField
	func has_action() -> bool:
		if __action.value != null:
			return true
		return false
	func get_action() -> GameAction:
		return __action.value
	func clear_action() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__action.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_action() -> GameAction:
		__action.value = GameAction.new()
		return __action.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameActionResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerInitData:
	func _init():
		var service
		
		__player_id = PBField.new("player_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __player_id
		data[__player_id.tag] = service
		
		__player_name = PBField.new("player_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __player_name
		data[__player_name.tag] = service
		
	var data = {}
	
	var __player_id: PBField
	func has_player_id() -> bool:
		if __player_id.value != null:
			return true
		return false
	func get_player_id() -> int:
		return __player_id.value
	func clear_player_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__player_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_player_id(value : int) -> void:
		__player_id.value = value
	
	var __player_name: PBField
	func has_player_name() -> bool:
		if __player_name.value != null:
			return true
		return false
	func get_player_name() -> String:
		return __player_name.value
	func clear_player_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__player_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_player_name(value : String) -> void:
		__player_name.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MatchRequest:
	func _init():
		var service
		
		__player_data = PBField.new("player_data", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player_data
		service.func_ref = Callable(self, "new_player_data")
		data[__player_data.tag] = service
		
	var data = {}
	
	var __player_data: PBField
	func has_player_data() -> bool:
		if __player_data.value != null:
			return true
		return false
	func get_player_data() -> PlayerInitData:
		return __player_data.value
	func clear_player_data() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__player_data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player_data() -> PlayerInitData:
		__player_data.value = PlayerInitData.new()
		return __player_data.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MatchResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__battle_id = PBField.new("battle_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __battle_id
		data[__battle_id.tag] = service
		
		__battle_server_addr = PBField.new("battle_server_addr", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __battle_server_addr
		data[__battle_server_addr.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __battle_id: PBField
	func has_battle_id() -> bool:
		if __battle_id.value != null:
			return true
		return false
	func get_battle_id() -> String:
		return __battle_id.value
	func clear_battle_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__battle_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_battle_id(value : String) -> void:
		__battle_id.value = value
	
	var __battle_server_addr: PBField
	func has_battle_server_addr() -> bool:
		if __battle_server_addr.value != null:
			return true
		return false
	func get_battle_server_addr() -> String:
		return __battle_server_addr.value
	func clear_battle_server_addr() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__battle_server_addr.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_battle_server_addr(value : String) -> void:
		__battle_server_addr.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum ErrorCode {
	OK = 0,
	INVALID_PARAM = 1,
	SERVER_ERROR = 2,
	AUTH_FAILED = 3,
	NOT_FOUND = 4,
	ALREADY_EXISTS = 5,
	NOT_ALLOWED = 6,
	NOT_SUPPORTED = 7,
	TIMEOUT = 8,
	INVALID_STATE = 9,
	INVALID_ACTION = 10,
	INVALID_CARD = 11,
	INVALID_ROOM = 12,
	INVALID_USER = 13,
	PLAYER_ALREADY_IN_ROOM = 14
}

enum MessageId {
	LOGIN_REQUEST = 0,
	LOGIN_RESPONSE = 1,
	AUTH_REQUEST = 2,
	AUTH_RESPONSE = 3,
	GET_USER_INFO_REQUEST = 4,
	GET_USER_INFO_RESPONSE = 5,
	GET_ROOM_LIST_REQUEST = 6,
	GET_ROOM_LIST_RESPONSE = 7,
	CREATE_ROOM_REQUEST = 8,
	CREATE_ROOM_RESPONSE = 9,
	JOIN_ROOM_REQUEST = 10,
	JOIN_ROOM_RESPONSE = 11,
	LEAVE_ROOM_REQUEST = 12,
	LEAVE_ROOM_RESPONSE = 13,
	ROOM_STATE_NOTIFICATION = 14,
	GAME_STATE_NOTIFICATION = 15,
	DRAW_CARD_REQUEST = 16,
	DRAW_CARD_RESPONSE = 17,
	GET_READY_REQUEST = 18,
	GET_READY_RESPONSE = 19,
	GAME_ACTION_REQUEST = 20,
	GAME_ACTION_RESPONSE = 21,
	GAME_ACTION_NOTIFICATION = 22
}

class Message:
	func _init():
		var service
		
		__clientId = PBField.new("clientId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __clientId
		data[__clientId.tag] = service
		
		__msgSerialNo = PBField.new("msgSerialNo", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __msgSerialNo
		data[__msgSerialNo.tag] = service
		
		__id = PBField.new("id", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__data = PBField.new("data", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __data
		data[__data.tag] = service
		
	var data = {}
	
	var __clientId: PBField
	func has_clientId() -> bool:
		if __clientId.value != null:
			return true
		return false
	func get_clientId() -> String:
		return __clientId.value
	func clear_clientId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__clientId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_clientId(value : String) -> void:
		__clientId.value = value
	
	var __msgSerialNo: PBField
	func has_msgSerialNo() -> bool:
		if __msgSerialNo.value != null:
			return true
		return false
	func get_msgSerialNo() -> int:
		return __msgSerialNo.value
	func clear_msgSerialNo() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__msgSerialNo.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_msgSerialNo(value : int) -> void:
		__msgSerialNo.value = value
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id():
		return __id.value
	func clear_id() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_id(value) -> void:
		__id.value = value
	
	var __data: PBField
	func has_data() -> bool:
		if __data.value != null:
			return true
		return false
	func get_data() -> PackedByteArray:
		return __data.value
	func clear_data() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_data(value : PackedByteArray) -> void:
		__data.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SkinInfo:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__description = PBField.new("description", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __description
		data[__description.tag] = service
		
		__price = PBField.new("price", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __price
		data[__price.tag] = service
		
		__image_url = PBField.new("image_url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __image_url
		data[__image_url.tag] = service
		
		__rarity = PBField.new("rarity", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __rarity
		data[__rarity.tag] = service
		
		__owned = PBField.new("owned", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __owned
		data[__owned.tag] = service
		
		__equipped = PBField.new("equipped", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __equipped
		data[__equipped.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __description: PBField
	func has_description() -> bool:
		if __description.value != null:
			return true
		return false
	func get_description() -> String:
		return __description.value
	func clear_description() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__description.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_description(value : String) -> void:
		__description.value = value
	
	var __price: PBField
	func has_price() -> bool:
		if __price.value != null:
			return true
		return false
	func get_price() -> int:
		return __price.value
	func clear_price() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__price.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_price(value : int) -> void:
		__price.value = value
	
	var __image_url: PBField
	func has_image_url() -> bool:
		if __image_url.value != null:
			return true
		return false
	func get_image_url() -> String:
		return __image_url.value
	func clear_image_url() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__image_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_image_url(value : String) -> void:
		__image_url.value = value
	
	var __rarity: PBField
	func has_rarity() -> bool:
		if __rarity.value != null:
			return true
		return false
	func get_rarity() -> String:
		return __rarity.value
	func clear_rarity() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__rarity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_rarity(value : String) -> void:
		__rarity.value = value
	
	var __owned: PBField
	func has_owned() -> bool:
		if __owned.value != null:
			return true
		return false
	func get_owned() -> bool:
		return __owned.value
	func clear_owned() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__owned.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_owned(value : bool) -> void:
		__owned.value = value
	
	var __equipped: PBField
	func has_equipped() -> bool:
		if __equipped.value != null:
			return true
		return false
	func get_equipped() -> bool:
		return __equipped.value
	func clear_equipped() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__equipped.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_equipped(value : bool) -> void:
		__equipped.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MarketItemsResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		var __items_default: Array[SkinInfo] = []
		__items = PBField.new("items", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __items_default)
		service = PBServiceField.new()
		service.field = __items
		service.func_ref = Callable(self, "add_items")
		data[__items.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __items: PBField
	func get_items() -> Array[SkinInfo]:
		return __items.value
	func clear_items() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__items.value.clear()
	func add_items() -> SkinInfo:
		var element = SkinInfo.new()
		__items.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BackpackItemsResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		var __items_default: Array[SkinInfo] = []
		__items = PBField.new("items", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __items_default)
		service = PBServiceField.new()
		service.field = __items
		service.func_ref = Callable(self, "add_items")
		data[__items.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __items: PBField
	func get_items() -> Array[SkinInfo]:
		return __items.value
	func clear_items() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__items.value.clear()
	func add_items() -> SkinInfo:
		var element = SkinInfo.new()
		__items.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PurchaseRequest:
	func _init():
		var service
		
		__item_id = PBField.new("item_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __item_id
		data[__item_id.tag] = service
		
		__item_type = PBField.new("item_type", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __item_type
		data[__item_type.tag] = service
		
	var data = {}
	
	var __item_id: PBField
	func has_item_id() -> bool:
		if __item_id.value != null:
			return true
		return false
	func get_item_id() -> String:
		return __item_id.value
	func clear_item_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__item_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_item_id(value : String) -> void:
		__item_id.value = value
	
	var __item_type: PBField
	func has_item_type() -> bool:
		if __item_type.value != null:
			return true
		return false
	func get_item_type() -> String:
		return __item_type.value
	func clear_item_type() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__item_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_item_type(value : String) -> void:
		__item_type.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PurchaseResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__item_id = PBField.new("item_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __item_id
		data[__item_id.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __item_id: PBField
	func has_item_id() -> bool:
		if __item_id.value != null:
			return true
		return false
	func get_item_id() -> String:
		return __item_id.value
	func clear_item_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__item_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_item_id(value : String) -> void:
		__item_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class EquipRequest:
	func _init():
		var service
		
		__item_id = PBField.new("item_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __item_id
		data[__item_id.tag] = service
		
	var data = {}
	
	var __item_id: PBField
	func has_item_id() -> bool:
		if __item_id.value != null:
			return true
		return false
	func get_item_id() -> String:
		return __item_id.value
	func clear_item_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__item_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_item_id(value : String) -> void:
		__item_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class EquipResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__item_id = PBField.new("item_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __item_id
		data[__item_id.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __item_id: PBField
	func has_item_id() -> bool:
		if __item_id.value != null:
			return true
		return false
	func get_item_id() -> String:
		return __item_id.value
	func clear_item_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__item_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_item_id(value : String) -> void:
		__item_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SkinDataRequest:
	func _init():
		var service
		
		__skin_id = PBField.new("skin_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __skin_id
		data[__skin_id.tag] = service
		
	var data = {}
	
	var __skin_id: PBField
	func has_skin_id() -> bool:
		if __skin_id.value != null:
			return true
		return false
	func get_skin_id() -> String:
		return __skin_id.value
	func clear_skin_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__skin_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_skin_id(value : String) -> void:
		__skin_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SkinDataResponse:
	func _init():
		var service
		
		__ret = PBField.new("ret", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __ret
		data[__ret.tag] = service
		
		__skin_id = PBField.new("skin_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __skin_id
		data[__skin_id.tag] = service
		
		__skin_data = PBField.new("skin_data", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __skin_data
		data[__skin_data.tag] = service
		
	var data = {}
	
	var __ret: PBField
	func has_ret() -> bool:
		if __ret.value != null:
			return true
		return false
	func get_ret():
		return __ret.value
	func clear_ret() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__ret.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_ret(value) -> void:
		__ret.value = value
	
	var __skin_id: PBField
	func has_skin_id() -> bool:
		if __skin_id.value != null:
			return true
		return false
	func get_skin_id() -> String:
		return __skin_id.value
	func clear_skin_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__skin_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_skin_id(value : String) -> void:
		__skin_id.value = value
	
	var __skin_data: PBField
	func has_skin_data() -> bool:
		if __skin_data.value != null:
			return true
		return false
	func get_skin_data() -> PackedByteArray:
		return __skin_data.value
	func clear_skin_data() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__skin_data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_skin_data(value : PackedByteArray) -> void:
		__skin_data.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DesktopPetPlayerState:
	func _init():
		var service
		
		__player_id = PBField.new("player_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __player_id
		data[__player_id.tag] = service
		
		__player_name = PBField.new("player_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __player_name
		data[__player_name.tag] = service
		
		__pet_skin = PBField.new("pet_skin", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __pet_skin
		data[__pet_skin.tag] = service
		
		__position_x = PBField.new("position_x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __position_x
		data[__position_x.tag] = service
		
		__position_y = PBField.new("position_y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __position_y
		data[__position_y.tag] = service
		
		__action = PBField.new("action", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __action
		data[__action.tag] = service
		
		__chat_text = PBField.new("chat_text", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __chat_text
		data[__chat_text.tag] = service
		
	var data = {}
	
	var __player_id: PBField
	func has_player_id() -> bool:
		if __player_id.value != null:
			return true
		return false
	func get_player_id() -> int:
		return __player_id.value
	func clear_player_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__player_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_player_id(value : int) -> void:
		__player_id.value = value
	
	var __player_name: PBField
	func has_player_name() -> bool:
		if __player_name.value != null:
			return true
		return false
	func get_player_name() -> String:
		return __player_name.value
	func clear_player_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__player_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_player_name(value : String) -> void:
		__player_name.value = value
	
	var __pet_skin: PBField
	func has_pet_skin() -> bool:
		if __pet_skin.value != null:
			return true
		return false
	func get_pet_skin() -> String:
		return __pet_skin.value
	func clear_pet_skin() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__pet_skin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_pet_skin(value : String) -> void:
		__pet_skin.value = value
	
	var __position_x: PBField
	func has_position_x() -> bool:
		if __position_x.value != null:
			return true
		return false
	func get_position_x() -> float:
		return __position_x.value
	func clear_position_x() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__position_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_position_x(value : float) -> void:
		__position_x.value = value
	
	var __position_y: PBField
	func has_position_y() -> bool:
		if __position_y.value != null:
			return true
		return false
	func get_position_y() -> float:
		return __position_y.value
	func clear_position_y() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__position_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_position_y(value : float) -> void:
		__position_y.value = value
	
	var __action: PBField
	func has_action() -> bool:
		if __action.value != null:
			return true
		return false
	func get_action() -> String:
		return __action.value
	func clear_action() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__action.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_action(value : String) -> void:
		__action.value = value
	
	var __chat_text: PBField
	func has_chat_text() -> bool:
		if __chat_text.value != null:
			return true
		return false
	func get_chat_text() -> String:
		return __chat_text.value
	func clear_chat_text() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__chat_text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_chat_text(value : String) -> void:
		__chat_text.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DesktopPetRoomState:
	func _init():
		var service
		
		__room_id = PBField.new("room_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __room_id
		data[__room_id.tag] = service
		
		var __players_default: Array[DesktopPetPlayerState] = []
		__players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __players_default)
		service = PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
	var data = {}
	
	var __room_id: PBField
	func has_room_id() -> bool:
		if __room_id.value != null:
			return true
		return false
	func get_room_id() -> String:
		return __room_id.value
	func clear_room_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__room_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_room_id(value : String) -> void:
		__room_id.value = value
	
	var __players: PBField
	func get_players() -> Array[DesktopPetPlayerState]:
		return __players.value
	func clear_players() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__players.value.clear()
	func add_players() -> DesktopPetPlayerState:
		var element = DesktopPetPlayerState.new()
		__players.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum DesktopPetMessageId {
	DESKTOP_PET_BASE = 0,
	DESKTOP_PET_AUTH_REQUEST = 1001,
	DESKTOP_PET_AUTH_RESPONSE = 1002,
	GET_MARKET_ITEMS_REQUEST = 1003,
	GET_MARKET_ITEMS_RESPONSE = 1004,
	GET_BACKPACK_ITEMS_REQUEST = 1005,
	GET_BACKPACK_ITEMS_RESPONSE = 1006,
	PURCHASE_REQUEST = 1007,
	PURCHASE_RESPONSE = 1008,
	EQUIP_REQUEST = 1009,
	EQUIP_RESPONSE = 1010,
	GET_SKIN_DATA_REQUEST = 1011,
	GET_SKIN_DATA_RESPONSE = 1012,
	PET_ACTION_NOTIFICATION = 1013,
	PET_CHAT_NOTIFICATION = 1014
}

################ USER DATA END #################
