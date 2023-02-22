module test.tiny_gltf;

import std.algorithm.mutation;
import std.string;

// @nogc nothrow:
// extern(C): __gshared:

// private template HasVersion(string versionId) {
// 	mixin("version("~versionId~") {enum HasVersion = true;} else {enum HasVersion = false;}");
// }

// import core.stdc.stddef: wchar_t;
//
// Header-only tiny glTF 2.0 loader and serializer.
// But now it's a D project, amazing.
//
//
// The MIT License (MIT)
//
// Copyright (c) 2015 - Present Syoyo Fujita, Aurélien Chatelain and many
// contributors.
// Now including jordan4ibanez, woo.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Version:
//  - v2.8.1 Missed serialization texture sampler name fixed. PR#399.
//  - v2.8.0 Add URICallbacks for custom URI handling in Buffer and Image. PR#397.
//  - v2.7.0 Change WriteImageDataFunction user callback function signature. PR#393.
//  - v2.6.3 Fix GLB file with empty BIN chunk was not handled. PR#382 and PR#383.
//  - v2.6.2 Fix out-of-bounds access of accessors. PR#379.
//  - v2.6.1 Better GLB validation check when loading.
//  - v2.6.0 Support serializing sparse accessor(Thanks to @fynv).
//           Disable expanding file path for security(no use of awkward `wordexp` anymore).
//  - v2.5.0 Add SetPreserveImageChannels() option to load image data as is.
//  - v2.4.3 Fix null object output when material has all default
//  parameters.
//  - v2.4.2 Decode percent-encoded URI.
//  - v2.4.1 Fix some glTF object class does not have `extensions` and/or
//  `extras` property.
//  - v2.4.0 Experimental RapidJSON and C++14 support(Thanks to @jrkoone).
//  - v2.3.1 Set default value of minFilter and magFilter in Sampler to -1.
//  - v2.3.0 Modified Material representation according to glTF 2.0 schema
//           (and introduced TextureInfo class)
//           Change the behavior of `Value::IsNumber`. It return true either the
//           value is int or real.
//  - v2.2.0 Add loading 16bit PNG support. Add Sparse accessor support(Thanks
//  to @Ybalrid)
//  - v2.1.0 Add draco compression.
//  - v2.0.1 Add comparison feature(Thanks to @Selmar).
//  - v2.0.0 glTF 2.0!.
//
// Tiny glTF loader is using following third party libraries:
//
//  - jsonhpp: C++ JSON library.
//  - base64: base64 decode/encode library.
//  - stb_image: Image loading library.
//


// enum string DEFAULT_METHODS(string x) = `             \
//   ~x() = default;                      \
//   x(const x &) = default;              \
//   x(x &&) TINYGLTF_NOEXCEPT = default; \
//   x &operator=(const x &) = default;   \
//   x &operator=(x &&) TINYGLTF_NOEXCEPT = default;`;

 // This was: namespace tinygltf {

enum TINYGLTF_MODE_POINTS = (0);
enum TINYGLTF_MODE_LINE = (1);
enum TINYGLTF_MODE_LINE_LOOP = (2);
enum TINYGLTF_MODE_LINE_STRIP = (3);
enum TINYGLTF_MODE_TRIANGLES = (4);
enum TINYGLTF_MODE_TRIANGLE_STRIP = (5);
enum TINYGLTF_MODE_TRIANGLE_FAN = (6);

enum TINYGLTF_COMPONENT_TYPE_BYTE = (5120);
enum TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE = (5121);
enum TINYGLTF_COMPONENT_TYPE_SHORT = (5122);
enum TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT = (5123);
enum TINYGLTF_COMPONENT_TYPE_INT = (5124);
enum TINYGLTF_COMPONENT_TYPE_UNSIGNED_INT = (5125);
enum TINYGLTF_COMPONENT_TYPE_FLOAT = (5126);
enum TINYGLTF_COMPONENT_TYPE_DOUBLE = 
  (5130);  // OpenGL double type. Note that some of glTF 2.0 validator does not;
          // support double type even the schema seems allow any value of
          // integer:
          // https://github.com/KhronosGroup/glTF/blob/b9884a2fd45130b4d673dd6c8a706ee21ee5c5f7/specification/2.0/schema/accessor.schema.json#L22

enum TINYGLTF_TEXTURE_FILTER_NEAREST = (9728);
enum TINYGLTF_TEXTURE_FILTER_LINEAR = (9729);
enum TINYGLTF_TEXTURE_FILTER_NEAREST_MIPMAP_NEAREST = (9984);
enum TINYGLTF_TEXTURE_FILTER_LINEAR_MIPMAP_NEAREST = (9985);
enum TINYGLTF_TEXTURE_FILTER_NEAREST_MIPMAP_LINEAR = (9986);
enum TINYGLTF_TEXTURE_FILTER_LINEAR_MIPMAP_LINEAR = (9987);

enum TINYGLTF_TEXTURE_WRAP_REPEAT = (10497);
enum TINYGLTF_TEXTURE_WRAP_CLAMP_TO_EDGE = (33071);
enum TINYGLTF_TEXTURE_WRAP_MIRRORED_REPEAT = (33648);

// Redeclarations of the above for technique.parameters.
enum TINYGLTF_PARAMETER_TYPE_BYTE = (5120);
enum TINYGLTF_PARAMETER_TYPE_UNSIGNED_BYTE = (5121);
enum TINYGLTF_PARAMETER_TYPE_SHORT = (5122);
enum TINYGLTF_PARAMETER_TYPE_UNSIGNED_SHORT = (5123);
enum TINYGLTF_PARAMETER_TYPE_INT = (5124);
enum TINYGLTF_PARAMETER_TYPE_UNSIGNED_INT = (5125);
enum TINYGLTF_PARAMETER_TYPE_FLOAT = (5126);

enum TINYGLTF_PARAMETER_TYPE_FLOAT_VEC2 = (35664);
enum TINYGLTF_PARAMETER_TYPE_FLOAT_VEC3 = (35665);
enum TINYGLTF_PARAMETER_TYPE_FLOAT_VEC4 = (35666);

enum TINYGLTF_PARAMETER_TYPE_INT_VEC2 = (35667);
enum TINYGLTF_PARAMETER_TYPE_INT_VEC3 = (35668);
enum TINYGLTF_PARAMETER_TYPE_INT_VEC4 = (35669);

enum TINYGLTF_PARAMETER_TYPE_BOOL = (35670);
enum TINYGLTF_PARAMETER_TYPE_BOOL_VEC2 = (35671);
enum TINYGLTF_PARAMETER_TYPE_BOOL_VEC3 = (35672);
enum TINYGLTF_PARAMETER_TYPE_BOOL_VEC4 = (35673);

enum TINYGLTF_PARAMETER_TYPE_FLOAT_MAT2 = (35674);
enum TINYGLTF_PARAMETER_TYPE_FLOAT_MAT3 = (35675);
enum TINYGLTF_PARAMETER_TYPE_FLOAT_MAT4 = (35676);

enum TINYGLTF_PARAMETER_TYPE_SAMPLER_2D = (35678);

// End parameter types

enum TINYGLTF_TYPE_VEC2 = (2);
enum TINYGLTF_TYPE_VEC3 = (3);
enum TINYGLTF_TYPE_VEC4 = (4);
enum TINYGLTF_TYPE_MAT2 = (32 + 2);
enum TINYGLTF_TYPE_MAT3 = (32 + 3);
enum TINYGLTF_TYPE_MAT4 = (32 + 4);
enum TINYGLTF_TYPE_SCALAR = (64 + 1);
enum TINYGLTF_TYPE_VECTOR = (64 + 4);
enum TINYGLTF_TYPE_MATRIX = (64 + 16);

enum TINYGLTF_IMAGE_FORMAT_JPEG = (0);
enum TINYGLTF_IMAGE_FORMAT_PNG = (1);
enum TINYGLTF_IMAGE_FORMAT_BMP = (2);
enum TINYGLTF_IMAGE_FORMAT_GIF = (3);

enum TINYGLTF_TEXTURE_FORMAT_ALPHA = (6406);
enum TINYGLTF_TEXTURE_FORMAT_RGB = (6407);
enum TINYGLTF_TEXTURE_FORMAT_RGBA = (6408);
enum TINYGLTF_TEXTURE_FORMAT_LUMINANCE = (6409);
enum TINYGLTF_TEXTURE_FORMAT_LUMINANCE_ALPHA = (6410);

enum TINYGLTF_TEXTURE_TARGET_TEXTURE2D = (3553);
enum TINYGLTF_TEXTURE_TYPE_UNSIGNED_BYTE = (5121);

enum TINYGLTF_TARGET_ARRAY_BUFFER = (34962);
enum TINYGLTF_TARGET_ELEMENT_ARRAY_BUFFER = (34963);

enum TINYGLTF_SHADER_TYPE_VERTEX_SHADER = (35633);
enum TINYGLTF_SHADER_TYPE_FRAGMENT_SHADER = (35632);

enum TINYGLTF_DOUBLE_EPS = (1.e-12);
enum string TINYGLTF_DOUBLE_EQUAL(string a, string b) = ` (std::fabs((b) - (a)) < TINYGLTF_DOUBLE_EPS)`;


enum Type {
    NULL_TYPE,
    REAL_TYPE,
    INT_TYPE,
    BOOL_TYPE,
    STRING_TYPE,
    ARRAY_TYPE,
    BINARY_TYPE,
    OBJECT_TYPE
}


pragma(inline, true) private int getComponentSizeInBytes(uint componentType) {
    if (componentType == TINYGLTF_COMPONENT_TYPE_BYTE) {
        return 1;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE) {
        return 1;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_SHORT) {
        return 2;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT) {
        return 2;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_INT) {
        return 4;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_INT) {
        return 4;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_FLOAT) {
        return 4;
    } else if (componentType == TINYGLTF_COMPONENT_TYPE_DOUBLE) {
        return 8;
    } else {
        // Unknown component type
        return -1;
    }
}

pragma(inline, true) private int GetNumComponentsInType(uint ty) {
    if (ty == TINYGLTF_TYPE_SCALAR) {
        return 1;
    } else if (ty == TINYGLTF_TYPE_VEC2) {
        return 2;
    } else if (ty == TINYGLTF_TYPE_VEC3) {
        return 3;
    } else if (ty == TINYGLTF_TYPE_VEC4) {
        return 4;
    } else if (ty == TINYGLTF_TYPE_MAT2) {
        return 4;
    } else if (ty == TINYGLTF_TYPE_MAT3) {
        return 9;
    } else if (ty == TINYGLTF_TYPE_MAT4) {
        return 16;
    } else {
        // Unknown component type
        return -1;
    }
}

// TODO(syoyo): Move these functions to TinyGLTF class
// bool IsDataURI(const(std) in_);
// bool DecodeDataURI(ubyte* out_, std mime_type, const(std) in_, size_t reqBytes, bool checkSize);

// Simple class to represent JSON object
//* Note: This whole thing is duck typed
class Value {

public:

    // C++ vector is dynamic array
    Value[] array;
    // C++ map is an Associative Array
    Value[string] object;

    this() {
        this.type_ = NULL_TYPE;
        this.int_value_ = 0;
        this.real_value_ = 0.0;
        this.boolean_value = false;
    }
    
    this(bool b) {
        boolean_value_ = b;
        this.type = BOOL_TYPE;
    }

    this(int i) {
        int_value_ = i;
        real_value_ = i;
        this.type = INT_TYPE;
    }

    this(double n) {
        real_value_ = n;
        this.type_ = REAL_TYPE;
    }

    this(string s) {
        string_value_ = s;
        this.type = STRING_TYPE;
    }

    this(string s) {
        move(string_value_, s);
        this.type = STRING_TYPE;
    }

    this(const char* p, size_t n) {
        binary_value_.resize(n);
        memcpy(binary_value_.data(), p, n);
        this.type = BINARY_TYPE;
    }

    this(ubyte[] v) {
        move(binary_value_, v);
        this.type = BINARY_TYPE;
    }
    
    this(const Array a) {
        array_value_ = a;
        this.type = ARRAY_TYPE;
    }

    this(Array a){
        move(array_value_, a);
        this.type = ARRAY_TYPE;
    }

    this(const Object o) {
        object_value_ = o;
        this.type = OBJECT_TYPE;
    }
    this(Object o){
        move(object_value_, o);
        this.type = OBJECT_TYPE;
    }

    tinygltf.type type(){
        return this.type_;
    }

    bool IsBool() {
        return (type_ == BOOL_TYPE);
    }

    bool IsInt() {
        return (type_ == INT_TYPE);
    }

    bool IsNumber() {
        return (type_ == REAL_TYPE) || (type_ == INT_TYPE);
    }

    bool IsReal() {
        return (type_ == REAL_TYPE);
    }

    bool IsString() {
        return (type_ == STRING_TYPE);
    }

    bool IsBinary() {
        return (type_ == BINARY_TYPE);
    }

    bool IsArray() {
        return (type_ == ARRAY_TYPE);
    }

    bool IsObject() {
        return (type_ == OBJECT_TYPE);
    }

    // Use this function if you want to have number value as double.
    double GetNumberAsDouble() {
        if (type_ == INT_TYPE) {
            return double(int_value_);
        } else {
            return real_value_;
        }
    }

    // Use this function if you want to have number value as int.
    // TODO(syoyo): Support int value larger than 32 bits
    int GetNumberAsInt() {
        if (type_ == REAL_TYPE) {
            return int(real_value_);
        } else {
            return int_value_;
        }
    }

    // Accessor
    template typename(T) {
        T typename;
    }
    // Lookup value from an array
    Value Get(int idx) const {
        static Value null_value;
        assert(IsArray());
        assert(idx >= 0);
        return (static_cast<size_t>(idx) < array_value_.size())? array_value_[static_cast<size_t>(idx)] : null_value;
    }

    // Lookup value from a key-value pair
    Value Get(const string key) const {
        static Value null_value;
        assert(IsObject());
        Object.const_iterator it = object_value_.find(key);
        return (it != object_value_.end()) ? it.second : null_value;
    }

    size_t ArrayLen() {
        if (!IsArray()) return 0;
        return array_value_.size();
    }

    // Valid only for object type.
    bool Has(const string key) {
        if (!IsObject()) return false;
        Object.const_iterator it = object_value_.find(key);
        return (it != object_value_.end()) ? true : false;
    }

    // List keys
    string[] Keys() const {
        string[] keys;
        if (!IsObject()) return keys;  // empty

        for (Object it = object_value_.begin(); it != object_value_.end(); ++it) {
                keys.push_back(it.first);
        }

        return keys;
    }

    size_t Size() {
        return (IsArray() ? ArrayLen() : Keys().size());
    }

    // This exists in D automatically
    // bool operator == (tinygltf::Value &other);


    //* Translation note: This is the more D way to do this than the weird mixin in C
    mixin(TINYGLTF_VALUE_GET("bool", "boolean_value_"));
    mixin(TINYGLTF_VALUE_GET("double", "real_value_"));
    mixin(TINYGLTF_VALUE_GET("int", "int_value_"));
    mixin(TINYGLTF_VALUE_GET("string", "string_value_"));
    mixin(TINYGLTF_VALUE_GET("ubyteArray", "binary_value_", "ubyte[]"));
    mixin(TINYGLTF_VALUE_GET("Array", "array_value_"));
    mixin(TINYGLTF_VALUE_GET("Object", "object_value_"));

protected:

    int type_ = NULL_TYPE;

    int int_value_ = 0;
    double real_value_ = 0.0;
    string string_value_;
    ubyte[] binary_value_;
    Array array_value_;
    Object object_value_;
    bool boolean_value_ = false;
    
}

//* Translation note: This is a C mixin generator!
string TINYGLTF_VALUE_GET(string ctype, string var, string returnType = "") {
    if (returnType == "") {
        returnType = ctype;
    }
    const string fancyCType = capitalize(ctype);
    return
    "\n" ~
    returnType ~ " Get" ~ fancyCType ~ "() const {\n" ~
         "return this." ~ var ~ ";\n" ~
    "}";
}

// * This is probably needed but check later
// TINYGLTF_VALUE_GET(bool, boolean_value_)
// TINYGLTF_VALUE_GET(double, real_value_)
// TINYGLTF_VALUE_GET(int, int_value_)
// TINYGLTF_VALUE_GET(std::string, string_value_)
// TINYGLTF_VALUE_GET(std::vector<unsigned char_>, binary_value_)
// TINYGLTF_VALUE_GET(Value::Array, array_value_)
// TINYGLTF_VALUE_GET(Value::Object, object_value_)
// version (__clang__) {
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wc++98-compat"
// #pragma clang diagnostic ignored "-Wpadded"
// }

/// Aggregate object for representing a color
alias ColorValue = double[4];

// === legacy interface ====
// TODO(syoyo): Deprecate `Parameter` class.
struct Parameter {
    bool bool_value = false;
    bool has_number_value = false;
    string string_value;/*::string string_value !!*/
    double[] number_array;/*:vector<double> number_array !!*/
    // Becomes an associative array
    int[string] json_double_value;/*:string, double> json_double_value !!*/
    double number_value = 0;

    // context sensitive methods. depending the type of the Parameter you are
    // accessing, these are either valid or not
    // If this parameter represent a texture map in a material, will return the
    // texture index

    /// Return the index of a texture if this Parameter is a texture map.
    /// Returned value is only valid if the parameter represent a texture from a
    /// material
    int TextureIndex() const {
        return json_double_value.get("index", -1);
    }

    /// Return the index of a texture coordinate set if this Parameter is a
    /// texture map. Returned value is only valid if the parameter represent a
    /// texture from a material
    int TextureTexCoord() const {
        // As per the spec, if texCoord is omitted, this parameter is 0
        return json_double_value.get("texCoord", 0);
    }

    /// Return the scale of a texture if this Parameter is a normal texture map.
    /// Returned value is only valid if the parameter represent a normal texture
    /// from a material
    double TextureScale() const {
        // As per the spec, if scale is omitted, this parameter is 1
        return json_double_value.get("scale", 1);
    }

    /// Return the strength of a texture if this Parameter is a an occlusion map.
    /// Returned value is only valid if the parameter represent an occlusion map
    /// from a material
    double TextureStrength() const {
        // As per the spec, if strength is omitted, this parameter is 1
        return json_double_value.get("strength", 1);
    }

    /// Material factor, like the roughness or metalness of a material
    /// Returned value is only valid if the parameter represent a texture from a
    /// material
    double Factor() const {
        return number_value;
    }

    /// Return the color of a material
    /// Returned value is only valid if the parameter represent a texture from a
    /// material
    ColorValue ColorFactor() {
        //* Translation note: This is an alias now, we can just return double[4]
        return
            [// this aggregate initialize the std::array object, and uses C++11 RVO.
            number_array[0], number_array[1], number_array[2],
            (number_array.size() > 3 ? number_array[3] : 1.0)
            ];
    }

    // * Translation note: I think these are unneeded
    //!TODO: Test if these are needed
    //   Parameter() = default;
    //    bool_; operator==cast(const(Parameter) &) const;
}

alias ParameterMap = Parameter[string];
alias ExtensionMap = ExtensionMap[string];

struct AnimationChannel {
    int sampler = -1;     // required
    int target_node = -1; // optional index of the node to target (alternative
                            // target should be provided by extension)
    string target_path;   // required with standard values of ["translation",
                            // "rotation", "scale", "weights"]
    Value extras;
    ExtensionMap extensions;
    ExtensionMap target_extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
    string target_extensions_json_string;

    this() {

    }/*: sampler(-1), target_node(-1) {}
    DEFAULT_METHODS(AnimationChannel)
    bool_ operator==cast(const(AnimationChannel) &) const !!*/
}

struct AnimationSampler {
    int input = -1;                   // required
    int output = -1;                  // required
    string interpolation = "LINEAR";  // "LINEAR", "STEP","CUBICSPLINE" or user defined
                                      // string. default "LINEAR"
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
    
    this(){

    }/*: input(-1), output(-1), interpolation("LINEAR") {}
    DEFAULT_METHODS(AnimationSampler)
    bool_ operator==cast(const(AnimationSampler) &) const !!*/
}

struct Animation {
    string name;
    AnimationChannel[] channels;
    AnimationSampler[] samplers;
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
    
    this() {

    }/*Animation() = default;
    DEFAULT_METHODS(Animation)
    bool operator==(const Animation &) const;*/
}

struct Skin {
    string name;
    int inverseBindMatrices = -1;  // required here but not in the spec
    int skeleton = -1;             // The index of the node used as a skeleton root
    int[] joints;                  // Indices of skeleton nodes

    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*DEFAULT_METHODS(Skin)
    bool operator==(const Skin &) const;*/
}

struct Sampler {
    string name;
    // glTF 2.0 spec does not define default value for `minFilter` and
    // `magFilter`. Set -1 in TinyGLTF(issue #186)

    int minFilter = -1;  // optional. -1 = no filter defined. ["NEAREST", "LINEAR",
                        // "NEAREST_MIPMAP_NEAREST", "LINEAR_MIPMAP_NEAREST",
                        // "NEAREST_MIPMAP_LINEAR", "LINEAR_MIPMAP_LINEAR"]

    int magFilter = -1;  // optional. -1 = no filter defined. ["NEAREST", "LINEAR"]

    int wrapS = TINYGLTF_TEXTURE_WRAP_REPEAT;  // ["CLAMP_TO_EDGE", "MIRRORED_REPEAT",
                                                // "REPEAT"], default "REPEAT"

    int wrapT = TINYGLTF_TEXTURE_WRAP_REPEAT;  // ["CLAMP_TO_EDGE", "MIRRORED_REPEAT",
                                                // "REPEAT"], default "REPEAT"

    int TINYGLTF_TEXTURE_WRAP_REPEAT;  // ["CLAMP_TO_EDGE", "MIRRORED_REPEAT",
                                        // "REPEAT"], default "REPEAT"

    int TINYGLTF_TEXTURE_WRAP_REPEAT;  // ["CLAMP_TO_EDGE", "MIRRORED_REPEAT",
                                        // "REPEAT"], default "REPEAT"

    // int wrapR = TINYGLTF_TEXTURE_WRAP_REPEAT;  // TinyGLTF extension. currently
    // not used.

    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*: minFilter(-1),
            magFilter(-1),
            wrapS(TINYGLTF_TEXTURE_WRAP_REPEAT),
            wrapT(TINYGLTF_TEXTURE_WRAP_REPEAT) {}
    DEFAULT_METHODS(Sampler)
    bool_ operator==cast(const(Sampler) &) const !!*/
}

struct Image {
    string name;
    int width = -1;
    int height = -1;
    int component = -1;
    int bits = -1;        // bit depth per channel. 8(byte), 16 or 32.
    int pixel_type = -1;  // pixel type(TINYGLTF_COMPONENT_TYPE_***). usually
                          // UBYTE(bits = 8) or USHORT(bits = 16)
    ubyte[] image;
    int bufferView = -1;  // (required if no uri)
    string mimeType;      // (required if no uri) ["image/jpeg", "image/png",
                          // "image/bmp", "image/gif"]
    string uri;           // (required if no mimeType) uri is not decoded(e.g.
                          // whitespace may be represented as %20)
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    // When this flag is true, data is stored to `image` in as-is format(e.g. jpeg
    // compressed for "image/jpeg" mime) This feature is good if you use custom
    // image loader function. (e.g. delayed decoding of images for faster glTF
    // parsing) Default parser for Image does not provide as-is loading feature at
    // the moment. (You can manipulate this by providing your own LoadImageData
    // function)
    bool as_is = false;

    this() {

    }/*: as_is(false) {
        bufferView = -1 !!
        width;
        height;
        component;
        bits;
        pixel_type;
    }Image DEFAULT_METHODS(Image);

    bool operator = cast(const(Image) &) const;*/
}

struct Texture {
    string name;

    int sampler = -1;
    int source = -1;
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {
        
    }/*: sampler(-1), source(-1) {}
    DEFAULT_METHODS(Texture)

    bool_ operator==cast(const(Texture) &) const !!*/
}

struct TextureInfo {
    int index = -1;     // required.
    int texCoord = 0;   // The set index of texture's TEXCOORD attribute used for
                        // texture coordinate mapping.

    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*: index(-1), texCoord(0) {}
    DEFAULT_METHODS(TextureInfo)
    bool_ operator==cast(const(TextureInfo) &) const !!*/
}

struct NormalTextureInfo {
    int index = -1;     // required
    int texCoord = 0;   // The set index of texture's TEXCOORD attribute used for
                        // texture coordinate mapping.
    double scale = 1.0; // scaledNormal = normalize((<sampled normal texture value>
                        // * 2.0 - 1.0) * vec3(<normal scale>, <normal scale>, 1.0))

    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*: index(-1), texCoord(0), scale(1.0) {}
    DEFAULT_METHODS(NormalTextureInfo)
    bool_ operator==cast(const(NormalTextureInfo) &) const !!*/
}

struct OcclusionTextureInfo {
    int index = -1;        // required
    int texCoord = 0;      // The set index of texture's TEXCOORD attribute used for
                           // texture coordinate mapping.
    double strength = 1.0; // occludedColor = lerp(color, color * <sampled occlusion
                           // texture value>, <occlusion strength>)

    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this(){

    }/*: index(-1), texCoord(0), strength(1.0) {}
    DEFAULT_METHODS(OcclusionTextureInfo)
    bool_ operator==cast(const(OcclusionTextureInfo) &) const !!*/
}

// pbrMetallicRoughness class defined in glTF 2.0 spec.
struct PbrMetallicRoughness {
    double[] baseColorFactor = [1.0,1.0,1.0,1.0];  // len = 4. default [1,1,1,1]
    TextureInfo baseColorTexture;
    double metallicFactor = 1.0;   // default 1
    double roughnessFactor = 1.0;  // default 1
    TextureInfo metallicRoughnessTexture;

    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {
        
    }/*: baseColorFactor(std::vector<double>{1.0, 1.0, 1.0, 1.0}),
            metallicFactor(1.0),
            roughnessFactor(1.0) {}
    DEFAULT_METHODS(PbrMetallicRoughness)
    bool_ operator==cast(const(PbrMetallicRoughness) &) const !!*/
}

// Each extension should be stored in a ParameterMap.
// members not in the values could be included in the ParameterMap
// to keep a single material model
struct Material {
    string name;

    double[] emissiveFactor = [0.0,0.0,0.0];  // length 3. default [0, 0, 0]
    string alphaMode = "OPAQUE";              // default "OPAQUE"
    double alphaCutoff = 0.5;                 // default 0.5
    bool doubleSided = false;                 // default false;

    PbrMetallicRoughness pbrMetallicRoughness;

    NormalTextureInfo normalTexture;
    OcclusionTextureInfo occlusionTexture;
    TextureInfo emissiveTexture;

    // For backward compatibility
    // TODO(syoyo): Remove `values` and `additionalValues` in the next release.
    ParameterMap values;
    ParameterMap additionalValues;

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*: alphaMode("OPAQUE"), alphaCutoff(0.5), doubleSided(false) {}
    DEFAULT_METHODS(Material)

    bool_ operator==cast(const(Material) &) const !!*/
}

struct BufferView {
    string name;
    int buffer = -1;        // Required
    size_t byteOffset = 0;  // minimum 0, default 0
    size_t byteLength = 0;  // required, minimum 1. 0 = invalid
    size_t byteStride = 0;  // minimum 4, maximum 252 (multiple of 4), default 0 =
                            // understood to be tightly packed
    int target = 0;  // ["ARRAY_BUFFER", "ELEMENT_ARRAY_BUFFER"] for vertex indices
                     // or attribs. Could be 0 for other data
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    bool dracoDecoded = false;  // Flag indicating this has been draco decoded

    this() {

    }/*: buffer(-1),
            byteOffset(0),
            byteLength(0),
            byteStride(0),
            target(0),
            dracoDecoded(false) {}
    DEFAULT_METHODS(BufferView)
    bool_ operator==cast(const(BufferView) &) const !!*/
}

struct Accessor {
    int bufferView = -1;  // optional in spec but required here since sparse accessor
                    // are not supported
    string name;
    size_t byteOffset = 0;
    bool normalized = false;    // optional.
    int componentType = -1;  // (required) One of TINYGLTF_COMPONENT_TYPE_***
    size_t count = 0;       // required
    int type = -1;           // (required) One of TINYGLTF_TYPE_***   ..
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    double[] minValues;  // optional. integer value is promoted to double
    double[]maxValues;   // optional. integer value is promoted to double

    struct _Sparse {
        int count;
        bool isSparse = false;
        struct _Indices {
            int byteOffset;
            int bufferView;
            int componentType;  // a TINYGLTF_COMPONENT_TYPE_ value
        }_Indices indices;
        struct _Values {
            int bufferView;
            int byteOffset;
            }_Values values;
    }_Sparse sparse;

    ///
    /// Utility function to compute byteStride for a given bufferView object.
    /// Returns -1 upon invalid glTF value or parameter configuration.
    ///
    int ByteStride(const BufferView bufferViewObject) const {
        if (bufferViewObject.byteStride == 0) {
            // Assume data is tightly packed.
            int componentSizeInBytes = GetComponentSizeInBytes(componentType);

            if (componentSizeInBytes <= 0) {
                return -1;
            }
            
            Accessor numComponents = GetNumComponentsInType(type);
            
            if (numComponents <= 0) {
                return -1;
            }

            return componentSizeInBytes * numComponents;

        } else {
            // Check if byteStride is a multiple of the size of the accessor's component
            // type.
            int componentSizeInBytes = GetComponentSizeInBytes(componentType);

            if (componentSizeInBytes <= 0) {
                return -1;
            }

            if ((bufferViewObject.byteStride % componentSizeInBytes) != 0) {
                return -1;
            }
            return bufferViewObject.byteStride;
        }

        // unreachable return 0;
        return 0;
    }

    this() {

    }/*Accessor()
        : bufferView(-1),
            byteOffset(0),
            normalized(false),
            componentType(-1),
            count(0),
            type(-1) {
        sparse.isSparse = false;
    }
    bool_; operator==cast(const(tinygltf)::Accessor &) const;*/
}

struct PerspectiveCamera {
    double aspectRatio = 0.0;  // min > 0
    double yfov = 0.0;         // required. min > 0
    double zfar = 0.0;         // min > 0
    double znear = 0.0;        // required. min > 0

    this() {

    }/*: aspectRatio(0.0),
            yfov(0.0),
            zfar(0.0)  // 0 = use infinite projection matrix
            ,
            znear(0.0) {}
    DEFAULT_METHODS(PerspectiveCamera)
    bool_ operator==cast(const(PerspectiveCamera) &) const !!*/

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

struct OrthographicCamera {
    double xmag = 0.0;   // required. must not be zero.
    double ymag = 0.0;   // required. must not be zero.
    double zfar = 0.0;   // required. `zfar` must be greater than `znear`.
    double znear = 0.0;  // required

    this() {

    }/*: xmag(0.0), ymag(0.0), zfar(0.0), znear(0.0) {}
    DEFAULT_METHODS(OrthographicCamera)
    bool_ operator==cast(const(OrthographicCamera) &) const !!*/

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

struct Camera {
    string type;  // required. "perspective" or "orthographic"
    string name;

    PerspectiveCamera perspective;
    OrthographicCamera orthographic;

    ExtensionMap extensions;
    Value extras;

    this() {

    }/*Camera() {}
    DEFAULT_METHODS(Camera)
    bool operator==(const Camera &) const;*/

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

struct Primitive {
    int[string] attributes; // (required) A dictionary object of
                            // integer, where each integer
                            // is the index of the accessor
                            // containing an attribute.
    int material = -1;  // The index of the material to apply to this primitive
                        // when rendering.
    int indices = -1;   // The index of the accessor that contains the indices.
    int mode = -1;      // one of TINYGLTF_MODE_***

    int[string][] targets;  // array of morph targets,
                            // where each target is a dict with attributes in ["POSITION, "NORMAL",
                            // "TANGENT"] pointing
                            // to their corresponding accessors

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*Primitive() {
        material = -1;
        indices = -1;
        mode = -1;
    }
    bool_; operator==cast(const(Primitive) &) const;*/
}

struct Mesh {
    string name;
    Primitive[] primitives;
    double[] weights;  // weights to be applied to the Morph Targets

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }
    /*Mesh() = default;
    DEFAULT_METHODS(Mesh)
    bool operator==(const Mesh &) const;*/
}

class Node {
public:
    this() {
        
    }
    // Node() : camera(-1), skin(-1), mesh(-1) {}
    // bool_ = void; operator==cast(const(Node) &) const;

    int camera = -1;  // the index of the camera referenced by this node

    string name;
    int skin = -1;
    int mesh = -1;
    int[] children;
    double[] rotation;     // length must be 0 or 4
    double[] scale;        // length must be 0 or 3
    double[] translation;  // length must be 0 or 3
    double[] matrix;       // length must be 0 or 16
    double[] weights;  // The weights of the instantiated Morph Target

    ExtensionMap extensions = void;
    Value extras = void;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

struct Buffer {
    string name;
    ubyte[] data;
    string uri;  // considered as required here but not in the spec (need to clarify)
                 // uri is not decoded(e.g. whitespace may be represented as %20)
    Value extras;
    ExtensionMap extensions;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {
        
    }/*Buffer() = default;
    DEFAULT_METHODS(Buffer)
    bool operator==(const Buffer &) const;*/
}

struct Asset {
    string version_ = "2.0"; // required
    string generator;
    string minVersion;
    string copyright;
    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {
        
    }/*Asset() = default;
    DEFAULT_METHODS(Asset)
    bool operator==(const Asset &) const;*/
}

struct Scene {
    string name;
    int[] nodes;

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;

    this() {

    }/*Scene() = default;
    DEFAULT_METHODS(Scene)
    bool operator==(const Scene &) const;*/
}

struct SpotLight {
    double innerConeAngle = 0.0;
    double outerConeAngle = 0.7_853_981_634;

    this() {

    }/*: innerConeAngle(0.0), outerConeAngle(0.7853981634) {}
    DEFAULT_METHODS(SpotLight)
    bool_ operator==cast(const(SpotLight) &) const !!*/

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

struct Light {
    string name;
    double[] color;
    double intensity = 1.0;
    string type;
    double range = 0.0;  // 0.0 = infinite
    SpotLight spot;

    this() {

    }/*: intensity(1.0), range(0.0) {}
    DEFAULT_METHODS(Light)

    bool_ operator==cast(const(Light) &) const !!*/

    ExtensionMap extensions;
    Value extras;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

class Model {
public:
    this() {

    }/*Model() = default;
    bool_ = void; operator==cast(const(Model) &) const;*/

    Accesso[] accessors;
    Animation[] animations;
    Buffer[] buffers;
    BufferView[] bufferViews;
    Material[] materials;
    Mesh[] meshes;
    Node[] nodes;
    Texture[] textures;
    Image[] images;
    Skin[] skins;
    Sampler[] samplers;
    Camera[] cameras;
    Scene[] scenes;
    Light[] lights;

    int defaultScene = -1;
    string extensionsUsed;
    string extensionsRequired;

    Asset asset = void;

    Value extras = void;
    ExtensionMap extensions = void;

    // Filled when SetStoreOriginalJSONForExtrasAndExtensions is enabled.
    string extras_json_string;
    string extensions_json_string;
}

enum SectionCheck {
    NO_REQUIRE = 0x00,
    REQUIRE_VERSION = 0x01,
    REQUIRE_SCENE = 0x02,
    REQUIRE_SCENES = 0x04,
    REQUIRE_NODES = 0x08,
    REQUIRE_ACCESSORS = 0x10,
    REQUIRE_BUFFERS = 0x20,
    REQUIRE_BUFFER_VIEWS = 0x40,
    REQUIRE_ALL = 0x7f
}
alias NO_REQUIRE = SectionCheck.NO_REQUIRE;
alias REQUIRE_VERSION = SectionCheck.REQUIRE_VERSION;
alias REQUIRE_SCENE = SectionCheck.REQUIRE_SCENE;
alias REQUIRE_SCENES = SectionCheck.REQUIRE_SCENES;
alias REQUIRE_NODES = SectionCheck.REQUIRE_NODES;
alias REQUIRE_ACCESSORS = SectionCheck.REQUIRE_ACCESSORS;
alias REQUIRE_BUFFERS = SectionCheck.REQUIRE_BUFFERS;
alias REQUIRE_BUFFER_VIEWS = SectionCheck.REQUIRE_BUFFER_VIEWS;
alias REQUIRE_ALL = SectionCheck.REQUIRE_ALL;


///
/// URIEncodeFunction type. Signature for custom URI encoding of external
/// resources such as .bin and image files. Used by tinygltf to re-encode the
/// final location of saved files. object_type may be used to encode buffer and
/// image URIs differently, for example. See
/// https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#uris
///
alias URIEncodeFunction = bool function(const(std) in_uri, const(std) object_type, std* out_uri, void* user_data);

///
/// URIDecodeFunction type. Signature for custom URI decoding of external
/// resources such as .bin and image files. Used by tinygltf when computing
/// filenames to write resources.
///
alias URIDecodeFunction = bool function(const(std) in_uri, std* out_uri, void* user_data);

// Declaration of default uri decode function
bool URIDecode(const(std) in_uri, std* out_uri, void* user_data);

///
/// A structure containing URI callbacks and a pointer to their user data.
///
struct URICallbacks {
    URIEncodeFunction encode;  // Optional encode method
    URIDecodeFunction decode;  // Required decode method

    void* user_data;  // An argument that is passed to all uri callbacks
}

///
/// LoadImageDataFunction type. Signature for custom image loading callbacks.
///
alias LoadImageDataFunction = bool function(Image*, const(int), std*, std*, int, int, const(ubyte)*, int, void* user_pointer);

///
/// WriteImageDataFunction type. Signature for custom image writing callbacks.
/// The out_uri parameter becomes the URI written to the gltf and may reference
/// a file or contain a data URI.
///
alias WriteImageDataFunction = bool function(const(std)* basepath, const(std)* filename, const(Image)* image, bool embedImages, const(URICallbacks)* uri_cb, std* out_uri, void* user_pointer);

version (TINYGLTF_NO_STB_IMAGE) {} else {
    // Declaration of default image loader callback
    bool LoadImageData(Image* image, const(int) image_idx, std* err, std* warn, int req_width, int req_height, const(ubyte)* bytes, int size, void*);
}

version (TINYGLTF_NO_STB_IMAGE_WRITE) {} else {
    // Declaration of default image writer callback
    bool WriteImageData(const(std)* basepath, const(std)* filename, const(Image)* image, bool embedImages, const(URICallbacks)* uri_cb, std* out_uri, void*);
}

///
/// FilExistsFunction type. Signature for custom filesystem callbacks.
///
alias FileExistsFunction = bool function(const(std) abs_filename, void*);

///
/// ExpandFilePathFunction type. Signature for custom filesystem callbacks.
///
alias ExpandFilePathFunction = string function(const ref string, void *);

///
/// ReadWholeFileFunction type. Signature for custom filesystem callbacks.
///
alias ReadWholeFileFunction = bool function(ubyte*, std*, const(std) string, void*);

///
/// WriteWholeFileFunction type. Signature for custom filesystem callbacks.
///
alias WriteWholeFileFunction = bool function(std*, const(std) string, const(std) vector, void*);

///
/// A structure containing all required filesystem callbacks and a pointer to
/// their user data.
///
struct FsCallbacks {
    FileExistsFunction FileExists;
    ExpandFilePathFunction ExpandFilePath;
    ReadWholeFileFunction ReadWholeFile;
    WriteWholeFileFunction WriteWholeFile;

    void* user_data;  // An argument that is passed to all fs callbacks
}

version (TINYGLTF_NO_FS) {} else {
// Declaration of default filesystem callbacks

bool FileExists(const(std) abs_filename, void*);

///
/// Expand file path(e.g. `~` to home directory on posix, `%APPDATA%` to
/// `C:\\Users\\tinygltf\\AppData`)
///
/// @param[in] filepath File path string. Assume UTF-8
/// @param[in] userdata User data. Set to `nullptr` if you don't need it.
///
string ExpandFilePath(const ref string filepath, void *userdata);

bool ReadWholeFile(ubyte* out_, std* err, const(std) filepath, void*);

bool WriteWholeFile(std* err, const(std) filepath, const(std) contents, void*);
}

///
/// glTF Parser/Serializer context.
///
class TinyGLTF {

public:

    this() {

    }/*TinyGLTF() : bin_data_(nullptr), bin_size_(0), is_binary_(false) {}*/

    //* Translation note: This literally did nothing
    // ~TinyGLTF() {}

    ///
    /// Loads glTF ASCII asset from a file.
    /// Set warning message to `warn` for example it fails to load asserts.
    /// Returns false and set error string to `err` if there's an error.
    ///
    bool LoadASCIIFromFile(Model* model, std* err, std* warn, const(std) filename, uint REQUIRE_VERSION);

    ///
    /// Loads glTF ASCII asset from string(memory).
    /// `length` = strlen(str);
    /// `base_dir` is a search path of glTF asset(e.g. images). Path Must be an
    /// expanded path (e.g. no tilde(`~`), no environment variables). Set warning
    /// message to `warn` for example it fails to load asserts. Returns false and
    /// set error string to `err` if there's an error.
    ///
    bool LoadASCIIFromString(Model* model, std* err, std* warn, const(char)* str, const(uint) length, const(std) base_dir, uint REQUIRE_VERSION);

    ///
    /// Loads glTF binary asset from a file.
    /// Set warning message to `warn` for example it fails to load asserts.
    /// Returns false and set error string to `err` if there's an error.
    ///
    bool LoadBinaryFromFile(Model* model, std* err, std* warn, const(std) filename, uint REQUIRE_VERSION);

    ///
    /// Loads glTF binary asset from memory.
    /// `length` = strlen(str);
    /// `base_dir` is a search path of glTF asset(e.g. images). Path Must be an
    /// expanded path (e.g. no tilde(`~`), no environment variables).
    /// Set warning message to `warn` for example it fails to load asserts.
    /// Returns false and set error string to `err` if there's an error.
    ///
    bool LoadBinaryFromMemory(Model* model, std* err, std* warn, const(ubyte)* bytes, const(uint) length, const(std) base_dir); bool unsigned = void; int check_sections = REQUIRE_VERSION;

    ///
    /// Write glTF to stream, buffers and images will be embedded
    ///
    bool WriteGltfSceneToStream(const(Model)* model, std stream, bool prettyPrint, bool writeBinary);

    ///
    /// Write glTF to file.
    ///
    bool WriteGltfSceneToFile(const(Model)* model, const(std) filename, bool embedImages, bool embedBuffers, bool prettyPrint, bool writeBinary);

    ///
    /// Set callback to use for loading image data
    ///
    void SetImageLoader(LoadImageDataFunction LoadImageData, void* user_data);

    ///
    /// Unset(remove) callback of loading image data
    ///
    void RemoveImageLoader();

    ///
    /// Set callback to use for writing image data
    ///
    void SetImageWriter(WriteImageDataFunction WriteImageData, void* user_data);

    ///
    /// Set callbacks to use for URI encoding and decoding and their user data
    ///
    void SetURICallbacks(URICallbacks callbacks);

    ///
    /// Set callbacks to use for filesystem (fs) access and their user data
    ///
    void SetFsCallbacks(FsCallbacks callbacks);

    ///
    /// Set serializing default values(default = false).
    /// When true, default values are force serialized to .glTF.
    /// This may be helpful if you want to serialize a full description of glTF
    /// data.
    ///
    /// TODO(LTE): Supply parsing option as function arguments to
    /// `LoadASCIIFromFile()` and others, not by a class method
    ///
    void SetSerializeDefaultValues(const(bool) enabled) {
        serialize_default_values_ = enabled;
    }

    bool GetSerializeDefaultValues() { return serialize_default_values_; }

    ///
    /// Store original JSON string for `extras` and `extensions`.
    /// This feature will be useful when the user want to reconstruct custom data
    /// structure from JSON string.
    ///
    void SetStoreOriginalJSONForExtrasAndExtensions(const(bool) enabled) {
        store_original_json_for_extras_and_extensions_ = enabled;
    }

    bool GetStoreOriginalJSONForExtrasAndExtensions() {
        return store_original_json_for_extras_and_extensions_;
    }

    ///
    /// Specify whether preserve image channels when loading images or not.
    /// (Not effective when the user supplies their own LoadImageData callbacks)
    ///
    void SetPreserveImageChannels(bool onoff) {
        preserve_image_channels_ = onoff;
    }

    bool GetPreserveImageChannels() { return preserve_image_channels_; }

private:
    ///
    /// Loads glTF asset from string(memory).
    /// `length` = strlen(str);
    /// Set warning message to `warn` for example it fails to load asserts
    /// Returns false and set error string to `err` if there's an error.
    ///
    bool LoadFromString(Model *model, string *err, string *warn,
                        const char_ *str, const uint length,
                        const ref string base_dir, uint check_sections);

    const(ubyte)* bin_data_ = nullptr;
    size_t bin_size_ = 0;
    bool is_binary_ = false;

    bool serialize_default_values_ = false;  ///< Serialize default values?

    bool store_original_json_for_extras_and_extensions_ = false;

    bool preserve_image_channels_ = false;  /// Default false(expand channels to
                                            /// RGBA) for backward compatibility.

    // Warning & error messages
    string warn_;
    string err_;

    FsCallbacks fs = [
        null, null, null, null
        /*
        #ifndef TINYGLTF_NO_FS

            &tinygltf::FileExists, &tinygltf::ExpandFilePath,
            &tinygltf::ReadWholeFile, &tinygltf::WriteWholeFile,

            nullptr  // Fs callback user data

        #else

            nullptr, nullptr, nullptr, nullptr,

            nullptr  // Fs callback user data

        #endif
        */
    ];
    

    URICallbacks uri_cb = URICallbacks(null, &tinygltf.URIDecode, null);
    /** This is what this used to look like in C kinda
        // Use paths as-is by default. This will use JSON string escaping.
        cast(URIEncodeFunction)0,
        // Decode all URIs before using them as paths as the application may have
        // percent encoded them.
        &tinygltf::URIDecode,
        // URI callback user data
        null
    );
    */

    LoadImageDataFunction LoadImageData = null;
    void *load_image_user_data_ = null;
    bool user_image_loader_ = false;

    WriteImageDataFunction WriteImageData = null;
    
    void *write_image_user_data_ = null;
}
// This was: }namespace tinygltf

  // TINY_GLTF_H_

// static if (HasVersion!"TINYGLTF_IMPLEMENTATION" || HasVersion!"__INTELLISENSE__") {
// public import 
// //#include <cassert>
// version (TINYGLTF_NO_FS) {} else {
// public import 
// public import 
// }
// public import 

// version (__clang__) {
// // Disable some warnings for external files.
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wfloat-equal"
// #pragma clang diagnostic ignored "-Wexit-time-destructors"
// #pragma clang diagnostic ignored "-Wconversion"
// #pragma clang diagnostic ignored "-Wold-style-cast"
// #pragma clang diagnostic ignored "-Wglobal-constructors"
// static if (__has_warning("-Wreserved-id-macro_")) {
// #pragma clang diagnostic ignored "-Wreserved-id-macro"
// }
// #pragma clang diagnostic ignored "-Wdisabled-macro-expansion"
// #pragma clang diagnostic ignored "-Wpadded"
// #pragma clang diagnostic ignored "-Wc++98-compat"
// #pragma clang diagnostic ignored "-Wc++98-compat-pedantic"
// #pragma clang diagnostic ignored "-Wdocumentation-unknown-command"
// #pragma clang diagnostic ignored "-Wswitch-enum"
// #pragma clang diagnostic ignored "-Wimplicit-fallthrough"
// #pragma clang diagnostic ignored "-Wweak-vtables"
// #pragma clang diagnostic ignored "-Wcovered-switch-default"
// static if (__has_warning("-Wdouble-promotion")) {
// #pragma clang diagnostic ignored "-Wdouble-promotion"
// }
// #if __has_warning("-Wcomma")
// #pragma clang diagnostic ignored "-Wcomma"
// }
// static if (__has_warning("-Wzero-as-null-pointer-constant")) {
// #pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"
// }
// static if (__has_warning("-Wcast-qual")) {
// #pragma clang diagnostic ignored "-Wcast-qual"
// }
// static if (__has_warning("-Wmissing-variable-declarations")) {
// #pragma clang diagnostic ignored "-Wmissing-variable-declarations"
// }
// static if (__has_warning("-Wmissing-prototypes")) {
// #pragma clang diagnostic ignored "-Wmissing-prototypes"
// }
// static if (__has_warning("-Wcast-align_")) {
// #pragma clang diagnostic ignored "-Wcast-align"
// }
// static if (__has_warning("-Wnewline-eof")) {
// #pragma clang diagnostic ignored "-Wnewline-eof"
// }
// static if (__has_warning("-Wunused-parameter")) {
// #pragma clang diagnostic ignored "-Wunused-parameter"
// }
// static if (__has_warning("-Wmismatched-tags")) {
// #pragma clang diagnostic ignored "-Wmismatched-tags"
// }
// static if (__has_warning("-Wextra-semi-stmt")) {
// #pragma clang diagnostic ignored "-Wextra-semi-stmt"
// }
// }

// version (TINYGLTF_NO_INCLUDE_JSON) {

// } else {
//     version (TINYGLTF_USE_RAPIDJSON) {

//     } else {
//         public import json.h;
//     } 
//     version (TINYGLTF_USE_RAPIDJSON) {
//         version (TINYGLTF_NO_INCLUDE_RAPIDJSON) {
            
//         } else {
//         public import document;
//         public import prettywriter;
//         public import rapidjson;
//         public import stringbuffer;
//         public import writer;
//         }
//     }
// }

// //! DRACO IMPORTED HERE
// version (TINYGLTF_ENABLE_DRACO) {
//     public import draco.compression.decode;
//     public import draco.core.decoder_buffer;
// }

// //! DEFINITION OF NO_STB_IMAGE AND STB_IMAGE IMPORT HERE!
// version (TINYGLTF_NO_STB_IMAGE) {} else {
//     version (TINYGLTF_NO_INCLUDE_STB_IMAGE) {} else {
//       public import stb_image;
//     }
// }

// //! STB IMAGE_WRITE IMPORTED HERE
// version (TINYGLTF_NO_STB_IMAGE_WRITE) {} else {
//     version (TINYGLTF_NO_INCLUDE_STB_IMAGE_WRITE) {} else {
//       public import stb_image_write;
//     }
// }

// version (Windows) {

//     // issue 143.
//     // Define NOMINMAX to avoid min/max defines,
//     // but undef it after included Windows.h
//     version (NOMINMAX) {} else {
//     version = TINYGLTF_INTERNAL_NOMINMAX;
//     version = NOMINMAX;
// }

 
// version = TINYGLTF_INTERNAL_WIN32_LEAN_AND_MEAN;

// version (Windows) {} else {
// public import Windows;  // include API for expanding a file path
// } version (Windows) {
// public import core.sys.windows.windows;
// }

// version (TINYGLTF_INTERNAL_WIN32_LEAN_AND_MEAN) {
// }

// version (TINYGLTF_INTERNAL_NOMINMAX) {
// }

// version (__GLIBCXX__) {  // mingw

// public import core.sys.posix.fcntl;  // _O_RDONLY

// public import ext/stdio_filebuf;  // fstream (all sorts of IO stuff) + stdio_filebuf (=streambuf)

// }

// } else static if (!HasVersion!"__ANDROID__" && !HasVersion!"__OpenBSD__") {
// //#include <wordexp.h>
// }

// static if (HasVersion!"__sparcv9" || HasVersion!"__powerpc__") {
// // Big endian
// } else {
// static if ((__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__) || MINIZ_X86_OR_X64_CPU) {
// enum TINYGLTF_LITTLE_ENDIAN = 1;
// }
// }

// namespace tinygltf {
//     namespace detail {
//         version (TINYGLTF_USE_RAPIDJSON) {
//             version (TINYGLTF_USE_RAPIDJSON_CRTALLOCATOR) {

//                     // This uses the RapidJSON CRTAllocator.  It is thread safe and multiple
//                     // documents may be active at once.
//                     using json = UTF8, CrtAllocator = void;
//                     using json_const_iterator = ConstMemberIterator;
//                     using json_const_array_iterator = const;
//                     using JsonDocument = UTF8, CrtAllocator = void;
//                     rapidjson::CrtAllocator s_CrtAllocator;  // stateless and thread safe
//                     rapidjson::CrtAllocator &GetAllocator() { return s_CrtAllocator; }

//                 } else {

//                     // This uses the default RapidJSON MemoryPoolAllocator.  It is very fast, but
//                     // not thread safe. Only a single JsonDocument may be active at any one time,
//                     // meaning only a single gltf load/save can be active any one time.
//                     using json = rapidjson;
//                     using json_const_iterator = ConstMemberIterator;
//                     using json_const_array_iterator = const;
//                     rapidjson::Document *s_pActiveDocument = nullptr;
//                     rapidjson::Document::AllocatorType &GetAllocator() {
//                     assert(s_pActiveDocument);  // Root json node must be JsonDocument type
//                     return s_pActiveDocument.GetAllocator();

//                 }
//                 JsonDocument Document {
//                     JsonDocument() {
//                         assert(s_pActiveDocument ==
//                             nullptr);  // When using default allocator, only one document can be
//                                         // active at a time, if you need multiple active at once,
//                                         // define TINYGLTF_USE_RAPIDJSON_CRTALLOCATOR
//                         s_pActiveDocument = this_;
//                     }
//                     delete = void;
//                     JsonDocument(JsonDocument &&rhs) noexcept
//                         : rapidjson::Document(std::move(rhs)) {
//                         s_pActiveDocument = this_;
//                         rhs.isNil = true;
//                     }
//                     ~JsonDocument() {
//                         if (!isNil) {
//                         s_pActiveDocument = nullptr;
//                         }
//                     }

//                     private:
//                     bool_ isNil = false;
//                 }

//             }  // TINYGLTF_USE_RAPIDJSON_CRTALLOCATOR

//         } else {
//             using nlohmann;
//             using json_const_iterator = const_iterator;
//             using json_const_array_iterator = json_const_iterator;
//             using JsonDocument = json;
//         }

//         void JsonParse(JsonDocument doc, const(char)* str, size_t length, bool throwExc = false) {
//             version (TINYGLTF_USE_RAPIDJSON) {
//                 cast(void)throwExc;
//                 doc.Parse(str, length);
//             } else {
//                 doc = detail::json::parse(str, str + length, nullptr, throwExc);
//             }
//         }
//     }  // namespace
// }

///
/// Internal LoadImageDataOption struct.
/// This struct is passed through `user_pointer` in LoadImageData.
/// The struct is not passed when the user supply their own LoadImageData
/// callbacks.
///
struct LoadImageDataOption {
    // true: preserve image channels(e.g. load as RGB image if the image has RGB
    // channels) default `false`(channels are expanded to RGBA for backward
    // compatibility).
    bool preserve_channels = void;
};

// Equals function for Value, for recursivity
private bool Equals(const tinygltf.Value one, const tinygltf.Value other) {
    
    if (one.Type() != other.Type()) {
        return false;
    };

    switch (one.Type()) {
        case NULL_TYPE:
            return true;
        case BOOL_TYPE:
            return one.GetBool() == other.GetBool();
        case REAL_TYPE: 
            return TINYGLTF_DOUBLE_EQUAL(one.GetDouble(), other.GetDouble());
        case INT_TYPE: 
            return one.GetInt() == other.GetInt();
        case OBJECT_TYPE: { 

            //* These are: Value[string] Object;
            const Value[string] oneObj = one.GetObject();
            const Value[string] otherObj = other.GetObject();

            if (oneObj.size() != otherObj.size())
                return false;
            
            foreach (const string it; oneObj) {
                const string otherIt = otherObj.find(it.first());

                if (otherIt == otherObj.end())
                    return false;

                if (!Equals(it.second, otherIt.second))
                    return false;
            }
            return true;
        }
        case ARRAY_TYPE: {
            if (one.Size() != other.Size()) return false;
            for (int i = 0; i < int(one.Size()); ++i)
                if (!Equals(one.Get(i), other.Get(i)))
                    return false;
            return true;
        }
        case STRING_TYPE:
            return one.GetString() == other.GetString();
        case BINARY_TYPE:
            return one.GetUbyteArray() == other.GetUbyteArray();
        default: {
            // unhandled type
            return false;
        }
    }
}

// Equals function for std::vector<double> using TINYGLTF_DOUBLE_EPSILON
private bool Equals(const(std) one, const(std) other) {
if (one.size() != other.size()) return false;
for (int i = 0; i < int(one.size()); ++i) {
    if (!TINYGLTF_DOUBLE_EQUAL(one[size_t(i)], other[size_t(i)])) return false;
}
return true;
}

// bool Accessor.operator==(Accessor other) const {

//     return this_.bufferView == other.bufferView &&
//             this_.byteOffset == other.byteOffset &&
//             this_.componentType == other.componentType &&
//             this_.count == other.count && this_.extensions == other.extensions &&
//             this_.extras == other.extras &&
//             Equals(this_.maxValues, other.maxValues) &&
//             Equals(this_.minValues, other.minValues) && this_.name == other.name &&
//             this_.normalized == other.normalized && this_.type == other.type;
// }
// bool Animation::operator==(Animation &other) const {
// return this_.channels == other.channels &&
//         this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.name == other.name && this_.samplers == other.samplers;
// }
// bool AnimationChannel::operator==(AnimationChannel &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.target_node == other.target_node &&
//         this_.target_path == other.target_path &&
//         this_.sampler == other.sampler;
// }
// bool AnimationSampler::operator==(AnimationSampler &other) const {
// return this_.extras == other.extras && this_.extensions == other.extensions &&
//         this_.input == other.input &&
//         this_.interpolation == other.interpolation &&
//         this_.output == other.output;
// }
// bool Asset::operator==(Asset &other) const {
// return this_.copyright == other.copyright &&
//         this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.generator == other.generator &&
//         this_.minVersion == other.minVersion && this_.version_ == other.version_;
// }
// bool Buffer::operator==(Buffer &other) const {
// return this_.data == other.data && this_.extensions == other.extensions &&
//         this_.extras == other.extras && this_.name == other.name &&
//         this_.uri == other.uri;
// }
// bool BufferView::operator==(BufferView &other) const {
// return this_.buffer == other.buffer && this_.byteLength == other.byteLength &&
//         this_.byteOffset == other.byteOffset &&
//         this_.byteStride == other.byteStride && this_.name == other.name &&
//         this_.target == other.target && this_.extensions == other.extensions &&
//         this_.extras == other.extras &&
//         this_.dracoDecoded == other.dracoDecoded;
// }
// bool Camera::operator==(Camera &other) const {
// return this_.name == other.name && this_.extensions == other.extensions &&
//         this_.extras == other.extras &&
//         this_.orthographic == other.orthographic &&
//         this_.perspective == other.perspective && this_.type == other.type;
// }
// bool Image::operator==(Image &other) const {
// return this_.bufferView == other.bufferView &&
//         this_.component == other.component &&
//         this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.height == other.height && this_.image == other.image &&
//         this_.mimeType == other.mimeType && this_.name == other.name &&
//         this_.uri == other.uri && this_.width == other.width;
// }
// bool Light::operator==(Light &other) const {
// return Equals(this_.color, other.color) && this_.name == other.name &&
//         this_.type == other.type;
// }
// bool Material::operator==(Material &other) const {
// return (this_.pbrMetallicRoughness == other.pbrMetallicRoughness) &&
//         (this_.normalTexture == other.normalTexture) &&
//         (this_.occlusionTexture == other.occlusionTexture) &&
//         (this_.emissiveTexture == other.emissiveTexture) &&
//         Equals(this_.emissiveFactor, other.emissiveFactor) &&
//         (this_.alphaMode == other.alphaMode) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.alphaCutoff, other.alphaCutoff) &&
//         (this_.doubleSided == other.doubleSided) &&
//         (this_.extensions == other.extensions) &&
//         (this_.extras == other.extras) && (this_.values == other.values) &&
//         (this_.additionalValues == other.additionalValues) &&
//         (this_.name == other.name);
// }
// bool Mesh::operator==(Mesh &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.name == other.name && Equals(this_.weights, other.weights) &&
//         this_.primitives == other.primitives;
// }
// bool Model::operator==(Model &other) const {
// return this_.accessors == other.accessors &&
//         this_.animations == other.animations && this_.asset == other.asset &&
//         this_.buffers == other.buffers &&
//         this_.bufferViews == other.bufferViews &&
//         this_.cameras == other.cameras &&
//         this_.defaultScene == other.defaultScene &&
//         this_.extensions == other.extensions &&
//         this_.extensionsRequired == other.extensionsRequired &&
//         this_.extensionsUsed == other.extensionsUsed &&
//         this_.extras == other.extras && this_.images == other.images &&
//         this_.lights == other.lights && this_.materials == other.materials &&
//         this_.meshes == other.meshes && this_.nodes == other.nodes &&
//         this_.samplers == other.samplers && this_.scenes == other.scenes &&
//         this_.skins == other.skins && this_.textures == other.textures;
// }
// bool Node::operator==(Node &other) const {
// return this_.camera == other.camera && this_.children == other.children &&
//         this_.extensions == other.extensions && this_.extras == other.extras &&
//         Equals(this_.matrix, other.matrix) && this_.mesh == other.mesh &&
//         this_.name == other.name && Equals(this_.rotation, other.rotation) &&
//         Equals(this_.scale, other.scale) && this_.skin == other.skin &&
//         Equals(this_.translation, other.translation) &&
//         Equals(this_.weights, other.weights);
// }
// bool SpotLight::operator==(SpotLight &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         TINYGLTF_DOUBLE_EQUAL(this_.innerConeAngle, other.innerConeAngle) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.outerConeAngle, other.outerConeAngle);
// }
// bool OrthographicCamera::operator==(OrthographicCamera &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         TINYGLTF_DOUBLE_EQUAL(this_.xmag, other.xmag) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.ymag, other.ymag) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.zfar, other.zfar) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.znear, other.znear);
// }
// bool Parameter::operator==(Parameter &other) const {
// if (this_.bool_value != other.bool_value ||
//     this_.has_number_value != other.has_number_value)
//     return false;

// if (!TINYGLTF_DOUBLE_EQUAL(this_.number_value, other.number_value))
//     return false;

// if (this_.json_double_value.size() != other.json_double_value.size())
//     return false;
// for (auto it otherIt = other.json_double_value.find(it.first);
//     if (otherIt == other.json_double_value.end()) return false;

//     if (!TINYGLTF_DOUBLE_EQUAL(it.second, otherIt.second)) return false;
// }

// if (!Equals(this_.number_array, other.number_array)) return false;

// if (this_.string_value != other.string_value) return false;

// return true;
// }
// bool PerspectiveCamera::operator==(PerspectiveCamera &other) const {
// return TINYGLTF_DOUBLE_EQUAL(this_.aspectRatio, other.aspectRatio) &&
//         this_.extensions == other.extensions && this_.extras == other.extras &&
//         TINYGLTF_DOUBLE_EQUAL(this_.yfov, other.yfov) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.zfar, other.zfar) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.znear, other.znear);
// }
// bool Primitive::operator==(Primitive &other) const {
// return this_.attributes == other.attributes && this_.extras == other.extras &&
//         this_.indices == other.indices && this_.material == other.material &&
//         this_.mode == other.mode && this_.targets == other.targets;
// }
// bool Sampler::operator==(Sampler &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.magFilter == other.magFilter &&
//         this_.minFilter == other.minFilter && this_.name == other.name &&
//         this_.wrapS == other.wrapS && this_.wrapT == other.wrapT;

// // this->wrapR == other.wrapR
// }
// bool Scene::operator==(Scene &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.name == other.name && this_.nodes == other.nodes;
// }
// bool Skin::operator==(Skin &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.inverseBindMatrices == other.inverseBindMatrices &&
//         this_.joints == other.joints && this_.name == other.name &&
//         this_.skeleton == other.skeleton;
// }
// bool Texture::operator==(Texture &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.name == other.name && this_.sampler == other.sampler &&
//         this_.source == other.source;
// }
// bool TextureInfo::operator==(TextureInfo &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.index == other.index && this_.texCoord == other.texCoord;
// }
// bool NormalTextureInfo::operator==(NormalTextureInfo &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.index == other.index && this_.texCoord == other.texCoord &&
//         TINYGLTF_DOUBLE_EQUAL(this_.scale, other.scale);
// }
// bool OcclusionTextureInfo::operator==(OcclusionTextureInfo &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         this_.index == other.index && this_.texCoord == other.texCoord &&
//         TINYGLTF_DOUBLE_EQUAL(this_.strength, other.strength);
// }
// bool PbrMetallicRoughness::operator==(PbrMetallicRoughness &other) const {
// return this_.extensions == other.extensions && this_.extras == other.extras &&
//         (this_.baseColorTexture == other.baseColorTexture) &&
//         (this_.metallicRoughnessTexture == other.metallicRoughnessTexture) &&
//         Equals(this_.baseColorFactor, other.baseColorFactor) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.metallicFactor, other.metallicFactor) &&
//         TINYGLTF_DOUBLE_EQUAL(this_.roughnessFactor, other.roughnessFactor);
// }
// bool Value::operator==(Value &other) const {
// return Equals(*this_, other);
// }

static void swap4(ref uint[4] val) {
    
    ubyte[4] dst = val;
    ubyte[4] src = val;

    dst[0] = src[3];
    dst[1] = src[2];
    dst[2] = src[1];
    dst[3] = src[0];

    val = dst;
}

private std JoinPath(const(string) path0, const(string) path1) {
    if (path0.empty()) {
        return path1;
    } else {
        // check '/'
        char lastChar = *path0.rbegin();
        if (lastChar != '/') {
            return path0 ~ string("/") ~ path1;
        } else {
            return path0 ~ path1;
        }
    }
}

private string FindFile(const(string) paths, const(string) filepath, FsCallbacks* fs) {
    if (fs == nullptr || fs.ExpandFilePath == nullptr ||
        fs.FileExists == nullptr) {
        // Error, fs callback[s] missing
        return "";
    }

    for (size_t i = 0; i < paths.size(); i++) {
        string absPath =
            fs.ExpandFilePath(JoinPath(paths[i], filepath), fs.user_data);
        if (fs.FileExists(absPath, fs.user_data)) {
        return absPath;
        }
    }

    return "";
}

private std GetFilePathExtension(const(string) FileName) {
    const int foundIndex = FileName.lastIndexOf(".");
    if (foundIndex != -1) {
        return "";
    }
    return to!string(FileName[(foundIndex + 1)..FileName.length]);
}

private std GetBaseDir(const(string) filepath) {
    const int foundIndex = filepath.lastIndexOf("/\\");
    if (foundIndex != -1) {
        return "";
    }
    return filepath[0..foundIndex];
}

private std GetBaseFilename(const(string) filepath) {
    auto idx = filepath.lastIndexOf("/\\");
    if (idx == -1) {
        return filepath;
    }
    return filepath[(idx + 1)..filepath.length];
}

//* Translation Note: Declarations
// string base64_encode(ubyte const *, unsigned int len);
// string base64_decode(string const &s);

/*
base64.cpp and base64.h

Copyright (C) 2004-2008 René Nyffenegger

This source code is provided 'as-is', without any express or implied
warranty. In no event will the author be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this source code must not be misrepresented; you must not
    claim that you wrote the original source code. If you use this source code
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original source code.

3. This notice may not be removed or altered from any source distribution.

René Nyffenegger rene.nyffenegger@adp-gmbh.ch

*/

// pragma(inline, true) private bool is_base64(ubyte c) {
// return (isalnum(c) || (c == '+') || (c == '/'));
// }

// std::string base64_encode(unsigned char_ const *bytes_to_encode,
//                         unsigned int in_len) {
// std::string ret;
// int i = 0;
// int j = 0;
// ubyte[3] char_array_3;
// ubyte[4] char_array_4;

// const(char)* base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
//     ~ "abcdefghijklmnopqrstuvwxyz"
//     ~ "0123456789+/";

// while (in_len--) {
//     char_array_3[i++] = *(bytes_to_encode++);
//     if (i == 3) {
//     char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
//     char_array_4[1] =
//         ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
//     char_array_4[2] =
//         ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
//     char_array_4[3] = char_array_3[2] & 0x3f;

//     for (i = 0; (i < 4); i++) ret += base64_chars[char_array_4[i]];
//     i = 0;
//     }
// }

// if (i) {
//     for (j = i; j < 3; j++) char_array_3[j] = '\0';

//     char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
//     char_array_4[1] =
//         ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
//     char_array_4[2] =
//         ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);

//     for (j = 0; (j < i + 1); j++) ret += base64_chars[char_array_4[j]];

//     while ((i++ < 3)) ret += '=';
// }

// return ret;
// }

// std::string base64_decode(std::string const &encoded_string) {
// int in_len = static_cast<int>(encoded_string.size());
// int i = 0;
// int j = 0;
// int in_ = 0;
// ubyte[4] char_array_4; ubyte[3] char_array_3;
// std::string ret;

// const(std) base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
//     ~ "abcdefghijklmnopqrstuvwxyz"
//     ~ "0123456789+/";

// while (in_len-- && (encoded_string[in_] != '=') &&
//         is_base64(encoded_string[in_])) {
//     char_array_4[i++] = encoded_string[in_];
//     in_++;
//     if (i == 4) {
//     for (i = 0; i < 4; i++)
//         char_array_4[i] =
//             static_cast<unsigned char_>(base64_chars.find(char_array_4[i]));

//     char_array_3[0] =
//         (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
//     char_array_3[1] =
//         ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
//     char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

//     for (i = 0; (i < 3); i++) ret += char_array_3[i];
//     i = 0;
//     }
// }

// if (i) {
//     for (j = i; j < 4; j++) char_array_4[j] = 0;

//     for (j = 0; j < 4; j++)
//     char_array_4[j] =
//         static_cast<unsigned char_>(base64_chars.find(char_array_4[j]));

//     char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
//     char_array_3[1] =
//         ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
//     char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

//     for (j = 0; (j < i - 1); j++) ret += char_array_3[j];
// }

// return ret;
// }
// version (__clang__) {
// #pragma clang diagnostic pop
// }

// https://github.com/syoyo/tinygltf/issues/228
// TODO(syoyo): Use uriparser https://uriparser.github.io/ for stricter Uri
// decoding?
//
// Uri Decoding from DLIB
// http://dlib.net/dlib/server/server_http.cpp.html
// --- dlib begin ------------------------------------------------------------
// Copyright (C) 2003  Davis E. King (davis@dlib.net)
// License: Boost Software License
// Boost Software License - Version 1.0 - August 17th, 2003

// Permission is hereby granted, free of charge, to any person or organization
// obtaining a copy of the software and accompanying documentation covered by
// this license (the "Software") to use, reproduce, display, distribute,
// execute, and transmit the Software, and to prepare derivative works of the
// Software, and to permit third-parties to whom the Software is furnished to
// do so, all subject to the following:
// The copyright notices in the Software and this entire statement, including
// the above license grant, this restriction and the following disclaimer,
// must be included in all copies of the Software, in whole or in part, and
// all derivative works of the Software, unless such copies or derivative
// works are solely in the form of machine-executable object code generated by
// a source language processor.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
// SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
// FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
// namespace dlib {

// pragma(inline, true) ubyte from_hex(ubyte ch) {
// if (ch <= '9' && ch >= '0')
//     ch -= '0';
// else if (ch <= 'f' && ch >= 'a')
//     ch -= 'a' - 10;
// else if (ch <= 'F' && ch >= 'A')
//     ch -= 'A' - 10;
// else
//     ch = 0;
// return ch;
// }

// private const(std) urldecode(const(std) str) {
// using namespace = void;
// string result = void;
// string::size_type i;
// for (i = 0; i < str.size(); ++i) {
//     if (str[i] == '+') {
//     result += ' ';
//     } else if (str[i] == '%' && str.size() > i + 2) {
//     const(ubyte) ch1 = from_hex(static_cast<unsigned char_>(str[i + 1]));
//     const(ubyte) ch2 = from_hex(static_cast<unsigned char_>(str[i + 2]));
//     const(ubyte) ch = static_cast<unsigned char_>((ch1 << 4) | ch2);
//     result += static_cast<char_>(ch);
//     i += 2;
//     } else {
//     result += str[i];
//     }
// }
// return result;
// }

// }  // namespace dlib
// // --- dlib end --------------------------------------------------------------

// bool URIDecode(const(std) in_uri, std* out_uri, void* user_data) {
// cast(void)user_data;
// *out_uri = dlib::urldecode(in_uri);
// return true;
// }

// private bool LoadExternalFile(ubyte* out_, std* err, std* warn, const(std) filename, const(std) basedir, bool required, size_t reqBytes, bool checkSize, FsCallbacks* fs) {
// if (fs == nullptr || fs.FileExists == nullptr ||
//     fs.ExpandFilePath == nullptr || fs.ReadWholeFile == nullptr) {
//     // This is a developer error, assert() ?
//     if (err) {
//     (*err) += "FS callback[s] not set\n";
//     }
//     return false;
// }

// std::string *failMsgOut = required ? err : warn;

// out_.clear();

// std::vector<std::string> paths;
// paths.push_back(basedir);
// paths.push_back(".");

// std::string filepath = FindFile(paths, filename, fs);
// if (filepath.empty() || filename.empty()) {
//     if (failMsgOut) {
//     (*failMsgOut) += "File not found : " + filename + "\n";
//     }
//     return false;
// }

// std::vector<unsigned char_> buf;
// std::string fileReadErr;
// bool fileRead = fs.ReadWholeFile(&buf, &fileReadErr, filepath, fs.user_data);
// if (!fileRead) {
//     if (failMsgOut) {
//     (*failMsgOut) +=
//         "File read error : " + filepath + " : " + fileReadErr + "\n";
//     }
//     return false;
// }

// size_t sz = buf.size();
// if (sz == 0) {
//     if (failMsgOut) {
//     (*failMsgOut) += "File is empty : " + filepath + "\n";
//     }
//     return false;
// }

// if (checkSize) {
//     if (reqBytes == sz) {
//     out_.swap(buf);
//     return true;
//     } else {
//     std::stringstream ss;
//     ss << "File size mismatch : " << filepath << ", requestedBytes "
//         << reqBytes << ", but got " << sz << std::endl;
//     if (failMsgOut) {
//         (*failMsgOut) += ss.str();
//     }
//     return false;
//     }
// }

// out_.swap(buf);
// return true;
// }

// void SetImageLoader(LoadImageDataFunction func, void* user_data) {
// LoadImageData = func;
// load_image_user_data_ = user_data;
// user_image_loader_ = true;
// }

// void RemoveImageLoader() {
// LoadImageData =
// #ifndef TINYGLTF_NO_STB_IMAGE
//     &tinygltf::LoadImageData;
// //! #else
//     nullptr;
// //! #endif

// load_image_user_data_ = nullptr;
// user_image_loader_ = false;
// }

// version (TINYGLTF_NO_STB_IMAGE) {} else {
// bool LoadImageData(Image* image, const(int) image_idx, std* err, std* warn, int req_width, int req_height, const(ubyte)* bytes, int size, void* user_data) {
// cast(void)warn;

// LoadImageDataOption option = void;
// if (user_data) {
//     option = *reinterpret_cast<LoadImageDataOption *>(user_data);
// }

// int w = 0, h = 0, comp = 0, req_comp = 0;

// ubyte* data = nullptr;

// // preserve_channels true: Use channels stored in the image file.
// // false: force 32-bit textures for common Vulkan compatibility. It appears
// // that some GPU drivers do not support 24-bit images for Vulkan
// req_comp = option.preserve_channels ? 0 : 4;
// int bits = 8;
// int pixel_type = TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE;

// // It is possible that the image we want to load is a 16bit per channel image
// // We are going to attempt to load it as 16bit per channel, and if it worked,
// // set the image data accordingly. We are casting the returned pointer into
// // unsigned char, because we are representing "bytes". But we are updating
// // the Image metadata to signal that this image uses 2 bytes (16bits) per
// // channel:
// if (stbi_is_16_bit_from_memory(bytes, size)) {
//     data = reinterpret_cast<unsigned char_ *>(
//         stbi_load_16_from_memory(bytes, size, &w, &h, &comp, req_comp));
//     if (data) {
//     bits = 16;
//     pixel_type = TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT;
//     }
// }

// // at this point, if data is still NULL, it means that the image wasn't
// // 16bit per channel, we are going to load it as a normal 8bit per channel
// // image as we used to do:
// // if image cannot be decoded, ignore parsing and keep it by its path
// // don't break in this case
// // FIXME we should only enter this function if the image is embedded. If
// // image->uri references
// // an image file, it should be left as it is. Image loading should not be
// // mandatory (to support other formats)
// if (!data) data = stbi_load_from_memory(bytes, size, &w, &h, &comp, req_comp);
// if (!data) {
//     // NOTE: you can use `warn` instead of `err`
//     if (err) {
//     (*err) +=
//         "Unknown image format. STB cannot decode image data for image[" +
//         std::to_string(image_idx) + "] name = \"" + image.name + "\".\n";
//     }
//     return false;
// }

// if ((w < 1) || (h < 1)) {
//     stbi_image_free(data);
//     if (err) {
//     (*err) += "Invalid image data for image[" + std::to_string(image_idx) +
//                 "] name = \"" + image.name + "\"\n";
//     }
//     return false;
// }

// if (req_width > 0) {
//     if (req_width != w) {
//     stbi_image_free(data);
//     if (err) {
//         (*err) += "Image width mismatch for image[" +
//                 std::to_string(image_idx) + "] name = \"" + image.name +
//                 "\"\n";
//     }
//     return false;
//     }
// }

// if (req_height > 0) {
//     if (req_height != h) {
//     stbi_image_free(data);
//     if (err) {
//         (*err) += "Image height mismatch. for image[" +
//                 std::to_string(image_idx) + "] name = \"" + image.name +
//                 "\"\n";
//     }
//     return false;
//     }
// }

// if (req_comp != 0) {
//     // loaded data has `req_comp` channels(components)
//     comp = req_comp;
// }

// image.width = w;
// image.height = h;
// image.component = comp;
// image.bits = bits;
// image.pixel_type = pixel_type;
// image.image.resize(static_cast<size_t>(w * h * comp) * size_t(bits / 8));
// std::copy(data, data + w * h * comp * (bits / 8), image.image.begin());
// stbi_image_free(data);

// return true;
// }
// }

// void SetImageWriter(WriteImageDataFunction func, void* user_data) {
// WriteImageData = func;
// write_image_user_data_ = user_data;
// }

// version (TINYGLTF_NO_STB_IMAGE_WRITE) {} else {
// private void WriteToMemory_stbi(void* context, void* data, int size) {
// std::vector<unsigned char_> *buffer =
//     reinterpret_cast<std::vector<unsigned char_> *>(context);

// ubyte* pData = reinterpret_cast<unsigned char_ *>(data);

// buffer.insert(buffer.end(), pData, pData + size);
// }

// bool WriteImageData(const(std)* basepath, const(std)* filename, const(Image)* image, bool embedImages, const(URICallbacks)* uri_cb, std* out_uri, void* fsPtr) {
// const(std) ext = GetFilePathExtension(*filename);

// // Write image to temporary buffer
// std::string header;
// std::vector<unsigned char_> data;

// if (ext == "png") {
//     if ((image.bits != 8) ||
//         (image.pixel_type != TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE)) {
//     // Unsupported pixel format
//     return false;
//     }

//     if (!stbi_write_png_to_func(&WriteToMemory_stbi, &data, image.width,
//                                 image.height, image.component,
//                                 &image.image[0], 0)) {
//     return false;
//     }
//     header = "data:image/png;base64,";
// } else if (ext == "jpg") {
//     if (!stbi_write_jpg_to_func(&WriteToMemory_stbi, &data, image.width,
//                                 image.height, image.component,
//                                 &image.image[0], 100)) {
//     return false;
//     }
//     header = "data:image/jpeg;base64,";
// } else if (ext == "bmp") {
//     if (!stbi_write_bmp_to_func(&WriteToMemory_stbi, &data, image.width,
//                                 image.height, image.component,
//                                 &image.image[0])) {
//     return false;
//     }
//     header = "data:image/bmp;base64,";
// } else if (!embedImages) {
//     // Error: can't output requested format to file
//     return false;
// }

// if (embedImages) {
//     // Embed base64-encoded image into URI
//     if (data.size()) {
//     *out_uri = header +
//                 base64_encode(&data[0], static_cast<unsigned int>(data.size()));
//     } else {
//     // Throw error?
//     }
// } else {
//     // Write image to disc
//     FsCallbacks* fs = reinterpret_cast<FsCallbacks *>(fsPtr);
//     if ((fs != nullptr) && (fs.WriteWholeFile != nullptr)) {
//     const(std) imagefilepath = JoinPath(*basepath, *filename);
//     std::string writeError;
//     if (!fs.WriteWholeFile(&writeError, imagefilepath, data,
//                             fs.user_data)) {
//         // Could not write image file to disc; Throw error ?
//         return false;
//     }
//     } else {
//     // Throw error?
//     }
//     if (uri_cb.encode) {
//     if (!uri_cb.encode(*filename, "image", out_uri, uri_cb.user_data)) {
//         return false;
//     }
//     } else {
//     *out_uri = *filename;
//     }
// }

// return true;
// }
// }

// void SetURICallbacks(URICallbacks callbacks) {
// assert(callbacks.decode);
// if (callbacks.decode) {
//     uri_cb = callbacks;
// }
// }

// void SetFsCallbacks(FsCallbacks callbacks) { fs = callbacks; }

// version (Windows) {
// pragma(inline, true) private std UTF8ToWchar(const(std) str) {
// int wstr_size = MultiByteToWideChar(CP_UTF8, 0, str.data(), cast(int)str.size(), nullptr, 0);
// std::wstring wstr(cast(size_t)wstr_size, 0);
// MultiByteToWideChar(CP_UTF8, 0, str.data(), cast(int)str.size(), &wstr[0],
//                     cast(int)wstr.size());
// return wstr;
// }

// pragma(inline, true) private std WcharToUTF8(const(std) wstr) {
// int str_size = WideCharToMultiByte(CP_UTF8, 0, wstr.data(), cast(int)wstr.size(),
//                                     nullptr, 0, nullptr, nullptr);
// std::string str(cast(size_t)str_size, 0);
// WideCharToMultiByte(CP_UTF8, 0, wstr.data(), cast(int)wstr.size(), &str[0],
//                     cast(int)str.size(), nullptr, nullptr);
// return str;
// }
// }

// version (TINYGLTF_NO_FS) {} else {
// // Default implementations of filesystem functions

// bool FileExists(const(std) abs_filename, void*) {
// bool ret = void;
// version (TINYGLTF_ANDROID_LOAD_FROM_ASSETS) {
// if (asset_manager) {
//     AAsset* asset = AAssetManager_open(asset_manager, abs_filename.c_str(),
//                                     AASSET_MODE_STREAMING);
//     if (!asset) {
//     return false;
//     }
//     AAsset_close(asset);
//     ret = true;
// } else {
//     return false;
// }
// } else {
// version (Windows) {
// static if (HasVersion!"_MSC_VER" || HasVersion!"__GLIBCXX__" || HasVersion!"_LIBCPP_VERSION") {
// FILE* fp = nullptr;
// errno_t err = _wfopen_s(&fp, UTF8ToWchar(abs_filename).c_str(), L"rb");
// if (err != 0) {
//     return false;
// }
// } else {
// FILE* fp = nullptr;
// errno_t err = fopen_s(&fp, abs_filename.c_str(), "rb");
// if (err != 0) {
//     return false;
// }
// }

// } else {
// FILE* fp = fopen(abs_filename.c_str(), "rb");
// }
// if (fp) {
//     ret = true;
//     fclose(fp);
// } else {
//     ret = false;
// }
// }

// return ret;
// }

// std::string ExpandFilePath(const std::string &filepath, void *) {
// // https://github.com/syoyo/tinygltf/issues/368
// //
// // No file path expansion in built-in FS function anymore, since glTF URI
// // should not contain tilde('~') and environment variables, and for security
// // reason(`wordexp`).
// //
// // Users need to supply `base_dir`(in `LoadASCIIFromString`,
// // `LoadBinaryFromMemory`) in expanded absolute path.

// return filepath;

// version (none) {
// version (Windows) {
// // Assume input `filepath` is encoded in UTF-8
// std::wstring wfilepath = UTF8ToWchar(filepath);
// DWORD wlen = ExpandEnvironmentStringsW(wfilepath.c_str(), nullptr, 0);
// wchar_t* wstr = wchar_t[wlen];
// ExpandEnvironmentStringsW(wfilepath.c_str(), wstr, wlen);

// std::wstring ws(wstr);
// delete[] wstr;
// return WcharToUTF8(ws);

// } else {

// static if (HasVersion!"TARGET_OS_IPHONE" || HasVersion!"TARGET_IPHONE_SIMULATOR" || \
//     HasVersion!"__ANDROID__" || HasVersion!"__EMSCRIPTEN__" || HasVersion!"__OpenBSD__") {
// // no expansion
// std::string s = filepath;
// } else {
// std::string s;
// wordexp_t p;

// if (filepath.empty()) {
//     return "";
// }

// // Quote the string to keep any spaces in filepath intact.
// std::string quoted_path = "\"" + filepath + "\"";
// // char** w;
// int ret = wordexp(quoted_path.c_str(), &p, 0);
// if (ret) {
//     // err
//     s = filepath;
//     return s;
// }

// // Use first element only.
// if (p.we_wordv) {
//     s = std::string(p.we_wordv[0]);
//     wordfree(&p);
// } else {
//     s = filepath;
// }

// }

// return s;
// }
// }
// }

// bool ReadWholeFile(ubyte* out_, std* err, const(std) filepath, void*) {
// version (TINYGLTF_ANDROID_LOAD_FROM_ASSETS) {
// if (asset_manager) {
//     AAsset* asset = AAssetManager_open(asset_manager, filepath.c_str(),
//                                     AASSET_MODE_STREAMING);
//     if (!asset) {
//     if (err) {
//         (*err) += "File open error : " + filepath + "\n";
//     }
//     return false;
//     }
//     size_t size = AAsset_getLength(asset);
//     if (size == 0) {
//     if (err) {
//         (*err) += "Invalid file size : " + filepath +
//                 " (does the path point to a directory?)";
//     }
//     return false;
//     }
//     out_.resize(size);
//     AAsset_read(asset, reinterpret_cast<char_ *>(&out_.at(0)), size);
//     AAsset_close(asset);
//     return true;
// } else {
//     if (err) {
//     (*err) += "No asset manager specified : " + filepath + "\n";
//     }
//     return false;
// }
// } else {
// version (Windows) {
// version (__GLIBCXX__) {  // mingw
// int file_descriptor = _wopen(UTF8ToWchar(filepath).c_str(), _O_RDONLY | _O_BINARY);
// __gnu_cxx::stdio_filebuf<char_> wfile_buf(file_descriptor, std::ios_base::in_);
// std::istream f(&wfile_buf);
// } else static if (HasVersion!"_MSC_VER" || HasVersion!"_LIBCPP_VERSION") {
// // For libcxx, assume _LIBCPP_HAS_OPEN_WITH_WCHAR is defined to accept
// // `wchar_t *`
// std::ifstream f(UTF8ToWchar(filepath).c_str(), std::ifstream::binary);
// } else {
// // Unknown compiler/runtime
// std::ifstream f(filepath.c_str(), std::ifstream::binary);
// }
// } else {
// std::ifstream f(filepath.c_str(), std::ifstream::binary);
// }
// if (!f) {
//     if (err) {
//     (*err) += "File open error : " + filepath + "\n";
//     }
//     return false;
// }

// f.seekg(0, f.end);
// size_t sz = static_cast<size_t>(f.tellg());
// f.seekg(0, f.beg);

// if (int64_t(sz) < 0) {
//     if (err) {
//     (*err) += "Invalid file size : " + filepath +
//                 " (does the path point to a directory?)";
//     }
//     return false;
// } else if (sz == 0) {
//     if (err) {
//     (*err) += "File is empty : " + filepath + "\n";
//     }
//     return false;
// }

// out_.resize(sz);
// f.read(reinterpret_cast<char_ *>(&out_.at(0)),
//         static_cast<std::streamsize>(sz));

// return true;
// }
// }

// bool WriteWholeFile(std* err, const(std) filepath, const(std) contents, void*) {
// version (Windows) {
// version (__GLIBCXX__) {  // mingw
// int file_descriptor = _wopen(UTF8ToWchar(filepath).c_str(),
//                             _O_CREAT | _O_WRONLY | _O_TRUNC | _O_BINARY);
// __gnu_cxx::stdio_filebuf<char_> wfile_buf(
//     file_descriptor, std::ios_base::out_ | std::ios_base::binary);
// std::ostream f(&wfile_buf);
// } else version (_MSC_VER) {
// std::ofstream f(UTF8ToWchar(filepath).c_str(), std::ofstream::binary);
// } else {  // clang?
// std::ofstream f(filepath.c_str(), std::ofstream::binary);
// }
// } else {
// std::ofstream f(filepath.c_str(), std::ofstream::binary);
// }
// if (!f) {
//     if (err) {
//     (*err) += "File open error for writing : " + filepath + "\n";
//     }
//     return false;
// }

// f.write(reinterpret_cast<const char_ *>(&contents.at(0)),
//         static_cast<std::streamsize>(contents.size()));
// if (!f) {
//     if (err) {
//     (*err) += "File write error: " + filepath + "\n";
//     }
//     return false;
// }

// return true;
// }

// }  // TINYGLTF_NO_FS

// private std MimeToExt(const(std) mimeType) {
// if (mimeType == "image/jpeg") {
//     return "jpg";
// } else if (mimeType == "image/png") {
//     return "png";
// } else if (mimeType == "image/bmp") {
//     return "bmp";
// } else if (mimeType == "image/gif") {
//     return "gif";
// }

// return "";
// }

// private bool UpdateImageObject(const(Image) image, std baseDir, int index, bool embedImages, const(URICallbacks)* uri_cb, WriteImageDataFunction* WriteImageData, void* user_data, std* out_uri) {
// std::string filename;
// std::string ext;
// // If image has uri, use it as a filename
// if (image.uri.size()) {
//     std::string decoded_uri;
//     if (!uri_cb.decode(image.uri, &decoded_uri, uri_cb.user_data)) {
//     // A decode failure results in a failure to write the gltf.
//     return false;
//     }
//     filename = GetBaseFilename(decoded_uri);
//     ext = GetFilePathExtension(filename);
// } else if (image.bufferView != -1) {
//     // If there's no URI and the data exists in a buffer,
//     // don't change properties or write images
// } else if (image.name.size()) {
//     ext = MimeToExt(image.mimeType);
//     // Otherwise use name as filename
//     filename = image.name + "." + ext;
// } else {
//     ext = MimeToExt(image.mimeType);
//     // Fallback to index of image as filename
//     filename = std::to_string(index) + "." + ext;
// }

// // If callback is set and image data exists, modify image data object. If
// // image data does not exist, this is not considered a failure and the
// // original uri should be maintained.
// bool imageWritten = false;
// if (*WriteImageData != nullptr && !filename.empty() && !image.image.empty()) {
//     imageWritten = (*WriteImageData)(&baseDir, &filename, &image, embedImages,
//                                     uri_cb, out_uri, user_data);
//     if (!imageWritten) {
//     return false;
//     }
// }

// // Use the original uri if the image was not written.
// if (!imageWritten) {
//     *out_uri = image.uri;
// }

// return true;
// }

// bool IsDataURI(const(std) in_) {
// std::string header = "data:application/octet-stream;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// header = "data:image/jpeg;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// header = "data:image/png;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// header = "data:image/bmp;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// header = "data:image/gif;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// header = "data:text/plain;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// header = "data:application/gltf-buffer;base64,";
// if (in_.find(header) == 0) {
//     return true;
// }

// return false;
// }

// bool DecodeDataURI(ubyte* out_, std mime_type, const(std) in_, size_t reqBytes, bool checkSize) {
// std::string header = "data:application/octet-stream;base64,";
// std::string data;
// if (in_.find(header) == 0) {
//     data = base64_decode(in_.substr(header.size()));  // cut mime string.
// }

// if (data.empty()) {
//     header = "data:image/jpeg;base64,";
//     if (in_.find(header) == 0) {
//     mime_type = "image/jpeg";
//     data = base64_decode(in_.substr(header.size()));  // cut mime string.
//     }
// }

// if (data.empty()) {
//     header = "data:image/png;base64,";
//     if (in_.find(header) == 0) {
//     mime_type = "image/png";
//     data = base64_decode(in_.substr(header.size()));  // cut mime string.
//     }
// }

// if (data.empty()) {
//     header = "data:image/bmp;base64,";
//     if (in_.find(header) == 0) {
//     mime_type = "image/bmp";
//     data = base64_decode(in_.substr(header.size()));  // cut mime string.
//     }
// }

// if (data.empty()) {
//     header = "data:image/gif;base64,";
//     if (in_.find(header) == 0) {
//     mime_type = "image/gif";
//     data = base64_decode(in_.substr(header.size()));  // cut mime string.
//     }
// }

// if (data.empty()) {
//     header = "data:text/plain;base64,";
//     if (in_.find(header) == 0) {
//     mime_type = "text/plain";
//     data = base64_decode(in_.substr(header.size()));
//     }
// }

// if (data.empty()) {
//     header = "data:application/gltf-buffer;base64,";
//     if (in_.find(header) == 0) {
//     data = base64_decode(in_.substr(header.size()));
//     }
// }

// // TODO(syoyo): Allow empty buffer? #229
// if (data.empty()) {
//     return false;
// }

// if (checkSize) {
//     if (data.size() != reqBytes) {
//     return false;
//     }
//     out_.resize(reqBytes);
// } else {
//     out_.resize(data.size());
// }
// std::copy(data.begin(), data.end(), out_.begin());
// return true;
// }

// namespace detail {
// bool GetInt(const(detail) o, int val) {
// version (TINYGLTF_USE_RAPIDJSON) {
// if (!o.IsDouble()) {
//     if (o.IsInt()) {
//     val = o.GetInt();
//     return true;
//     } else if (o.IsUint()) {
//     val = static_cast<int>(o.GetUint());
//     return true;
//     } else if (o.IsInt64()) {
//     val = static_cast<int>(o.GetInt64());
//     return true;
//     } else if (o.IsUint64()) {
//     val = static_cast<int>(o.GetUint64());
//     return true;
//     }
// }

// return false;
// } else {
// auto type = o.type();

// if ((type == detail::json::value_t::number_integer) ||
//     (type == detail::json::value_t::number_unsigned)) {
//     val = static_cast<int>(o.get<int64_t>());
//     return true;
// }

// return false;
// }
// }

// version (TINYGLTF_USE_RAPIDJSON) {
// bool GetDouble(const(detail) o, double val) {
// if (o.IsDouble()) {
//     val = o.GetDouble();
//     return true;
// }

// return false;
// }
// }

// bool GetNumber(const(detail) o, double val) {
// version (TINYGLTF_USE_RAPIDJSON) {
// if (o.IsNumber()) {
//     val = o.GetDouble();
//     return true;
// }

// return false;
// } else {
// if (o.is_number()) {
//     val = o.get<double>();
//     return true;
// }

// return false;
// }
// }

// bool GetString(const(detail) o, std val) {
// version (TINYGLTF_USE_RAPIDJSON) {
// if (o.IsString()) {
//     val = o.GetString();
//     return true;
// }

// return false;
// } else {
// if (o.type() == detail::json::value_t::string) {
//     val = o.get<std::string>();
//     return true;
// }

// return false;
// }
// }

// bool IsArray(const(detail) o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.IsArray();
// } else {
// return o.is_array();
// }
// }

// detail::json_const_array_iterator ArrayBegin(const detail::json &o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.Begin();
// } else {
// return o.begin();
// }
// }

// detail::json_const_array_iterator ArrayEnd(const detail::json &o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.End();
// } else {
// return o.end();
// }
// }

// bool IsObject(const(detail) o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.IsObject();
// } else {
// return o.is_object();
// }
// }

// detail::json_const_iterator ObjectBegin(const detail::json &o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.MemberBegin();
// } else {
// return o.begin();
// }
// }

// detail::json_const_iterator ObjectEnd(const detail::json &o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.MemberEnd();
// } else {
// return o.end();
// }
// }

// // Making this a const char* results in a pointer to a temporary when
// // TINYGLTF_USE_RAPIDJSON is off.
// std::string GetKey(detail::json_const_iterator &it) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return it.name.GetString();
// } else {
// return it.key().c_str();
// }
// }

// bool FindMember(const(detail) o, const(char)* member, detail it) {
// version (TINYGLTF_USE_RAPIDJSON) {
// if (!o.IsObject()) {
//     return false;
// }
// it = o.FindMember(member);
// return it != o.MemberEnd();
// } else {
// it = o.find(member);
// return it != o.end();
// }
// }

// const(detail) GetValue(detail it) {
//     version (TINYGLTF_USE_RAPIDJSON) {
//         return it.value;
//     } else {
//         return it.value();
//     }
// }

// std::string JsonToString(const detail::json &o, int spacing = -1) {
// version (TINYGLTF_USE_RAPIDJSON) {
// using rapidjson;
// StringBuffer buffer;
// if (spacing == -1) {
//     Writer<StringBuffer> writer(buffer);
//     // TODO: Better error handling.
//     // https://github.com/syoyo/tinygltf/issues/332
//     if (!o.Accept(writer)) {
//     return "tiny_gltf::JsonToString() failed rapidjson conversion";
//     }
// } else {
//     PrettyWriter<StringBuffer> writer(buffer);
//     writer.SetIndent(' ', uint32_t(spacing));
//     if (!o.Accept(writer)) {
//     return "tiny_gltf::JsonToString() failed rapidjson conversion";
//     }
// }
// return buffer.GetString();
// } else {
// return o.dump(spacing);
// }
// }

// }  // namespace

// private bool ParseJsonAsValue(Value* ret, const(detail) o) {
// Value val {}{}
// version (TINYGLTF_USE_RAPIDJSON) {
// using rapidjson;
// switch (o.GetType()) {
//     case Type::kObjectType: {
//     Value::Object value_object;
//     for (auto it = o.MemberBegin(); it != o.MemberEnd(); ++it) {
//         Value entry;
//         ParseJsonAsValue(&entry, it.value);
//         if (entry.Type() != NULL_TYPE)
//         value_object.emplace(detail::GetKey(it), std::move(entry));
//     }
//     if (value_object.size() > 0) val = Value(std::move(value_object));
//     } break;
//     case Type::kArrayType: {
//     Value::Array value_array;
//     value_array.reserve(o.Size());
//     for (auto it = o.Begin(); it != o.End(); ++it) {
//         Value entry;
//         ParseJsonAsValue(&entry, *it);
//         if (entry.Type() != NULL_TYPE)
//         value_array.emplace_back(std::move(entry));
//     }
//     if (value_array.size() > 0) val = Value(std::move(value_array));
//     } break;
//     case Type::kStringType:
//     val = Value(std::string(o.GetString()));
//     break;
//     case Type::kFalseType:
//     case Type::kTrueType:
//     val = Value(o.GetBool());
//     break;
//     case Type::kNumberType:
//     if (!o.IsDouble()) {
//         int i = 0;
//         detail::GetInt(o, i);
//         val = Value(i);
//     } else {
//         double d = 0.0;
//         detail::GetDouble(o, d);
//         val = Value(d);
//     }
//     break;
//     case Type::kNullType:
//     break;
//     // all types are covered, so no `case default`
// default: break;}
// } else {
// switch (o.type()) {
//     case detail::json::value_t::object: {
//     Value::Object value_object;
//     for (auto it = o.begin(); it != o.end(); it++) {
//         Value entry;
//         ParseJsonAsValue(&entry, it.value());
//         if (entry.Type() != NULL_TYPE)
//         value_object.emplace(it.key(), std::move(entry));
//     }
//     if (value_object.size() > 0) val = Value(std::move(value_object));
//     } break;
//     case detail::json::value_t::array: {
//     Value::Array value_array;
//     value_array.reserve(o.size());
//     for (auto it = o.begin(); it != o.end(); it++) {
//         Value entry;
//         ParseJsonAsValue(&entry, it.value());
//         if (entry.Type() != NULL_TYPE)
//         value_array.emplace_back(std::move(entry));
//     }
//     if (value_array.size() > 0) val = Value(std::move(value_array));
//     } break;
//     case detail::json::value_t::string:
//     val = Value(o.get<std::string>());
//     break;
//     case detail::json::value_t::boolean:
//     val = Value(o.get<bool_>());
//     break;
//     case detail::json::value_t::number_integer:
//     case detail::json::value_t::number_unsigned:
//     val = Value(static_cast<int>(o.get<int64_t>()));
//     break;
//     case detail::json::value_t::number_float:
//     val = Value(o.get<double>());
//     break;
//     case detail::json::value_t::null:
//     case detail::json::value_t::discarded:
//     case detail::json::value_t::binary:
//     // default:
//     break;
// default: break;}
// }
// const(bool) isNotNull = val.Type() != NULL_TYPE;

// if (ret) *ret = std::move(val);

// return isNotNull;
// }

// private bool ParseExtrasProperty(Value* ret, const(detail) o) {
// detail::json_const_iterator it;
// if (!detail::FindMember(o, "extras", it)) {
//     return false;
// }

// return ParseJsonAsValue(ret, detail::GetValue(it));
// }

// private bool ParseBooleanProperty(bool* ret, std* err, const(detail) o, const(std) property, const(bool) required, const(std) parent_node);
//     return false;
// }

// auto &value = detail::GetValue(it);

// bool isBoolean;
// bool boolValue = false;
// version (TINYGLTF_USE_RAPIDJSON) {
// isBoolean = value.IsBool();
// if (isBoolean) {
//     boolValue = value.GetBool();
// }
// } else {
// isBoolean = value.is_boolean();
// if (isBoolean) {
//     boolValue = value.get<bool_>();
// }
// }
// if (!isBoolean) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not a bool type.\n";
//     }
//     }
//     return false;
// }

// if (ret) {
//     (*ret) = boolValue;
// }

// return true;
// }

// private bool ParseIntegerProperty(int* ret, std* err, const(detail) o, const(std) property, const(bool) required, const(std) parent_node);
//     return false;
// }

// int intValue;
// bool isInt = GetInt(detail::GetValue(it), intValue);
// if (!isInt) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not an integer type.\n";
//     }
//     }
//     return false;
// }

// if (ret) {
//     (*ret) = intValue;
// }

// return true;
// }

// private bool ParseUnsignedProperty(size_t* ret, std* err, const(detail) o, const(std) property, const(bool) required, const(std) parent_node);
//     return false;
// }

// auto &value = detail::GetValue(it);

// size_t uValue = 0;
// bool isUValue;
// version (TINYGLTF_USE_RAPIDJSON) {
// isUValue = false;
// if (value.IsUint()) {
//     uValue = value.GetUint();
//     isUValue = true;
// } else if (value.IsUint64()) {
//     uValue = value.GetUint64();
//     isUValue = true;
// }
// } else {
// isUValue = value.is_number_unsigned();
// if (isUValue) {
//     uValue = value.get<size_t>();
// }
// }
// if (!isUValue) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not a positive integer.\n";
//     }
//     }
//     return false;
// }

// if (ret) {
//     (*ret) = uValue;
// }

// return true;
// }

// private bool ParseNumberProperty(double* ret, std* err, const(detail) o, const(std) property, const(bool) required, const(std) parent_node);
//     return false;
// }

// double numberValue = 0;
// bool isNumber = GetNumber(detail::GetValue(it), numberValue);

// if (!isNumber) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not a number type.\n";
//     }
//     }
//     return false;
// }

// if (ret) {
//     (*ret) = numberValue;
// }

// return true;
// }

// private bool ParseNumberArrayProperty(std* ret, std* err, const(detail) o, const(std) property, bool required, const(std) parent_node);
//     return false;
// }

// if (!detail::IsArray(detail::GetValue(it))) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not an array";
//         if (!parent_node.empty()) {
//         (*err) += " in " + parent_node;
//         }
//         (*err) += ".\n";
//     }
//     }
//     return false;
// }

// ret.clear();
// auto end ArrayEnd(detail GetValue(it));
// for (auto i ArrayBegin(detail GetValue(it)); i != end; ++i) {
//     double numberValue = 0;
//     const(bool) isNumber = GetNumber(*i, numberValue);
//     if (!isNumber) {
//     if (required) {
//         if (err) {
//         (*err) += "'" + property + "' property is not a number.\n";
//         if (!parent_node.empty()) {
//             (*err) += " in " + parent_node;
//         }
//         (*err) += ".\n";
//         }
//     }
//     return false;
//     }
//     ret.push_back(numberValue);
// }

// return true;
// }

// private bool ParseIntegerArrayProperty(std* ret, std* err, const(detail) o, const(std) property, bool required, const(std) parent_node);
//     return false;
// }

// if (!detail::IsArray(detail::GetValue(it))) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not an array";
//         if (!parent_node.empty()) {
//         (*err) += " in " + parent_node;
//         }
//         (*err) += ".\n";
//     }
//     }
//     return false;
// }

// ret.clear();
// auto end ArrayEnd(detail GetValue(it));
// for (auto i ArrayBegin(detail GetValue(it)); i != end; ++i) {
//     int numberValue;
//     bool isNumber = GetInt(*i, numberValue);
//     if (!isNumber) {
//     if (required) {
//         if (err) {
//         (*err) += "'" + property + "' property is not an integer type.\n";
//         if (!parent_node.empty()) {
//             (*err) += " in " + parent_node;
//         }
//         (*err) += ".\n";
//         }
//     }
//     return false;
//     }
//     ret.push_back(numberValue);
// }

// return true;
// }

// private bool ParseStringProperty(std* ret, std* err, const(detail) o, const(std) property, bool required, const(std) string()) {
// detail::json_const_iterator it;
// if (!detail::FindMember(o, property.c_str(), it)) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is missing";
//         if (parent_node.empty()) {
//         (*err) += ".\n";
//         } else {
//         (*err) += " in `" + parent_node + "'.\n";
//         }
//     }
//     }
//     return false;
// }

// std::string strValue;
// if (!detail::GetString(detail::GetValue(it), strValue)) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not a string type.\n";
//     }
//     }
//     return false;
// }

// if (ret) {
//     (*ret) = std::move(strValue);
// }

// return true;
// }

// private bool ParseStringIntegerProperty(std string, int* ret, std* err, const(detail) o, const(std) property, bool required, const(std) parent);

// const(detail) dict = GetValue(it);

// // Make sure we are dealing with an object / dictionary.
// if (!detail::IsObject(dict)) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not an object.\n";
//     }
//     }
//     return false;
// }

// ret.clear();

// detail::json_const_iterator dictIt(detail::ObjectBegin(dict));
// detail::json_const_iterator dictItEnd(detail::ObjectEnd(dict));

// for (; dictIt != dictItEnd; ++dictIt) {
//     int intVal;
//     if (!detail::GetInt(detail::GetValue(dictIt), intVal)) {
//     if (required) {
//         if (err) {
//         (*err) += "'" + property + "' value is not an integer type.\n";
//         }
//     }
//     return false;
//     }

//     // Insert into the list.
//     (*ret)[detail::GetKey(dictIt)] = intVal;
// }
// return true;
// }

// private bool ParseJSONProperty(std string, double* ret, std* err, const(detail) o, const(std) property, bool required) {
// detail::json_const_iterator it;
// if (!detail::FindMember(o, property.c_str(), it)) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is missing. \n'";
//     }
//     }
//     return false;
// }

// const(detail) obj = GetValue(it);

// if (!detail::IsObject(obj)) {
//     if (required) {
//     if (err) {
//         (*err) += "'" + property + "' property is not a JSON object.\n";
//     }
//     }
//     return false;
// }

// ret.clear();

// detail::json_const_iterator it2(detail::ObjectBegin(obj));
// detail::json_const_iterator itEnd(detail::ObjectEnd(obj));
// for (; it2 != itEnd; ++it2) {
//     double numVal = void;
//     if (detail::GetNumber(detail::GetValue(it2), numVal))
//     ret.emplace(std::string(detail::GetKey(it2)), numVal);
// }

// return true;
// }

// private bool ParseParameterProperty(Parameter* param, std* err, const(detail) o, const(std) prop, bool required) {
// // A parameter value can either be a string or an array of either a boolean or
// // a number. Booleans of any kind aren't supported here. Granted, it
// // complicates the Parameter structure and breaks it semantically in the sense
// // that the client probably works off the assumption that if the string is
// // empty the vector is used, etc. Would a tagged union work?
// if (ParseStringProperty(&param.string_value, err, o, prop, false)) {
//     // Found string property.
//     return true;
// } else if (ParseNumberArrayProperty(&param.number_array, err, o, prop,
//                                     false)) {
//     // Found a number array.
//     return true;
// } else if (ParseNumberProperty(&param.number_value, err, o, prop, false)) {
//     param.has_number_value = true;
//     return true;
// } else if (ParseJSONProperty(&param.json_double_value, err, o, prop,
//                             false)) {
//     return true;
// } else if (ParseBooleanProperty(&param.bool_value, err, o, prop, false)) {
//     return true;
// } else {
//     if (required) {
//     if (err) {
//         (*err) += "parameter must be a string or number / number array.\n";
//     }
//     }
//     return false;
// }
// }

// private bool ParseExtensionsProperty(ExtensionMap* ret, std* err, const(detail) o) {
// cast(void)err;

// detail::json_const_iterator it;
// if (!detail::FindMember(o, "extensions", it)) {
//     return false;
// }

// auto &obj = detail::GetValue(it);
// if (!detail::IsObject(obj)) {
//     return false;
// }
// ExtensionMap extensions = void;
// detail::json_const_iterator extIt = detail::ObjectBegin(obj);  // it.value().begin();
// detail::json_const_iterator extEnd = detail::ObjectEnd(obj);
// for (; extIt != extEnd; ++extIt) {
//     auto &itObj = detail::GetValue(extIt);
//     if (!detail::IsObject(itObj)) continue;
//     std::string key(detail::GetKey(extIt));
//     if (!ParseJsonAsValue(&extensions[key], itObj)) {
//     if (!key.empty()) {
//         // create empty object so that an extension object is still of type
//         // object
//         extensions[key] = Value{Value::Object{}}{}
//     }
//     }
// }
// if (ret) {
//     (*ret) = std::move(extensions);
// }
// return true;
// }

// private bool ParseAsset(Asset* asset, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseStringProperty(&asset.version_, err, o, "version", true, "Asset");
// ParseStringProperty(&asset.generator, err, o, "generator", false, "Asset");
// ParseStringProperty(&asset.minVersion, err, o, "minVersion", false, "Asset");
// ParseStringProperty(&asset.copyright, err, o, "copyright", false, "Asset");

// ParseExtensionsProperty(&asset.extensions, err, o);

// // Unity exporter version is added as extra here
// ParseExtrasProperty(&(asset.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         asset.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         asset.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseImage(Image* image, const(int) image_idx, std* err, std* warn, const(detail) o, bool store_original_json_for_extras_and_extensions, const(std) basedir, FsCallbacks* fs, const(URICallbacks)* uri_cb, LoadImageDataFunction nullptr, void nullptr) {
// // A glTF image must either reference a bufferView or an image uri

// // schema says oneOf [`bufferView`, `uri`]
// // TODO(syoyo): Check the type of each parameters.
// detail::json_const_iterator it;
// bool hasBufferView = FindMember(o, "bufferView", it);
// bool hasURI = FindMember(o, "uri", it);

// ParseStringProperty(&image.name, err, o, "name", false);

// if (hasBufferView && hasURI) {
//     // Should not both defined.
//     if (err) {
//     (*err) +=
//         "Only one of `bufferView` or `uri` should be defined, but both are "
//         ~ "defined for image[" +
//         std::to_string(image_idx) + "] name = \"" + image.name + "\"\n";
//     }
//     return false;
// }

// if (!hasBufferView && !hasURI) {
//     if (err) {
//     (*err) += "Neither required `bufferView` nor `uri` defined for image[" +
//                 std::to_string(image_idx) + "] name = \"" + image.name +
//                 "\"\n";
//     }
//     return false;
// }

// ParseExtensionsProperty(&image.extensions, err, o);
// ParseExtrasProperty(&image.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator eit;
//     if (detail::FindMember(o, "extensions", eit)) {
//         image.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator eit;
//     if (detail::FindMember(o, "extras", eit)) {
//         image.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// if (hasBufferView) {
//     int bufferView = -1;
//     if (!ParseIntegerProperty(&bufferView, err, o, "bufferView", true)) {
//     if (err) {
//         (*err) += "Failed to parse `bufferView` for image[" +
//                 std::to_string(image_idx) + "] name = \"" + image.name +
//                 "\"\n";
//     }
//     return false;
//     }

//     std::string mime_type;
//     ParseStringProperty(&mime_type, err, o, "mimeType", false);

//     int width = 0;
//     ParseIntegerProperty(&width, err, o, "width", false);

//     int height = 0;
//     ParseIntegerProperty(&height, err, o, "height", false);

//     // Just only save some information here. Loading actual image data from
//     // bufferView is done after this `ParseImage` function.
//     image.bufferView = bufferView;
//     image.mimeType = mime_type;
//     image.width = width;
//     image.height = height;

//     return true;
// }

// // Parse URI & Load image data.

// std::string uri;
// std::string tmp_err;
// if (!ParseStringProperty(&uri, &tmp_err, o, "uri", true)) {
//     if (err) {
//     (*err) += "Failed to parse `uri` for image[" + std::to_string(image_idx) +
//                 "] name = \"" + image.name + "\".\n";
//     }
//     return false;
// }

// std::vector<unsigned char_> img;

// if (IsDataURI(uri)) {
//     if (!DecodeDataURI(&img, image.mimeType, uri, 0, false)) {
//     if (err) {
//         (*err) += "Failed to decode 'uri' for image[" +
//                 std::to_string(image_idx) + "] name = [" + image.name +
//                 "]\n";
//     }
//     return false;
//     }
// } else {
//     // Assume external file
//     // Keep texture path (for textures that cannot be decoded)
//     image.uri = uri;
// version (TINYGLTF_NO_EXTERNAL_IMAGE) {
//     return true;
// } else {
//     std::string decoded_uri;
//     if (!uri_cb.decode(uri, &decoded_uri, uri_cb.user_data)) {
//     if (warn) {
//         (*warn) += "Failed to decode 'uri' for image[" +
//                 std::to_string(image_idx) + "] name = [" + image.name +
//                 "]\n";
//     }

//     // Image loading failure is not critical to overall gltf loading.
//     return true;
//     }

//     if (!LoadExternalFile(&img, err, warn, decoded_uri, basedir,
//                         /* required */ false, /* required bytes */ 0,
//                         /* checksize */ false, fs)) {
//     if (warn) {
//         (*warn) += "Failed to load external 'uri' for image[" +
//                 std::to_string(image_idx) + "] name = [" + image.name +
//                 "]\n";
//     }
//     // If the image cannot be loaded, keep uri as image->uri.
//     return true;
//     }

//     if (img.empty()) {
//     if (warn) {
//         (*warn) += "Image data is empty for image[" +
//                 std::to_string(image_idx) + "] name = [" + image.name +
//                 "] \n";
//     }
//     return false;
//     }
// }
// }

// if (*LoadImageData == nullptr) {
//     if (err) {
//     (*err) += "No LoadImageData callback specified.\n";
//     }
//     return false;
// }
// return (*LoadImageData)(image, image_idx, err, warn, 0, 0, &img.at(0),
//                         static_cast<int>(img.size()), load_image_user_data);
// }

// private bool ParseTexture(Texture* texture, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions, const(std) basedir) {
// cast(void)basedir;
// int sampler = -1;
// int source = -1;
// ParseIntegerProperty(&sampler, err, o, "sampler", false);

// ParseIntegerProperty(&source, err, o, "source", false);

// texture.sampler = sampler;
// texture.source = source;

// ParseExtensionsProperty(&texture.extensions, err, o);
// ParseExtrasProperty(&texture.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         texture.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         texture.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// ParseStringProperty(&texture.name, err, o, "name", false);

// return true;
// }

// private bool ParseTextureInfo(TextureInfo* texinfo, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// if (texinfo == nullptr) {
//     return false;
// }

// if (!ParseIntegerProperty(&texinfo.index, err, o, "index",
//                             /* required */ true, "TextureInfo")) {
//     return false;
// }

// ParseIntegerProperty(&texinfo.texCoord, err, o, "texCoord", false);

// ParseExtensionsProperty(&texinfo.extensions, err, o);
// ParseExtrasProperty(&texinfo.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         texinfo.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         texinfo.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseNormalTextureInfo(NormalTextureInfo* texinfo, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// if (texinfo == nullptr) {
//     return false;
// }

// if (!ParseIntegerProperty(&texinfo.index, err, o, "index",
//                             /* required */ true, "NormalTextureInfo")) {
//     return false;
// }

// ParseIntegerProperty(&texinfo.texCoord, err, o, "texCoord", false);
// ParseNumberProperty(&texinfo.scale, err, o, "scale", false);

// ParseExtensionsProperty(&texinfo.extensions, err, o);
// ParseExtrasProperty(&texinfo.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         texinfo.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         texinfo.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseOcclusionTextureInfo(OcclusionTextureInfo* texinfo, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// if (texinfo == nullptr) {
//     return false;
// }

// if (!ParseIntegerProperty(&texinfo.index, err, o, "index",
//                             /* required */ true, "NormalTextureInfo")) {
//     return false;
// }

// ParseIntegerProperty(&texinfo.texCoord, err, o, "texCoord", false);
// ParseNumberProperty(&texinfo.strength, err, o, "strength", false);

// ParseExtensionsProperty(&texinfo.extensions, err, o);
// ParseExtrasProperty(&texinfo.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         texinfo.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         texinfo.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseBuffer(Buffer* buffer, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions, FsCallbacks* fs, const(URICallbacks)* uri_cb, const(std) basedir, bool is_binary); private bool const; ubyte* bin_data = nullptr; ubyte bin_size = {
// size_t byteLength;
// if (!ParseUnsignedProperty(&byteLength, err, o, "byteLength", true,
//                             "Buffer")) {
//     return false;
// };
// buffer.uri.clear();
// ParseStringProperty(&buffer.uri, err, o, "uri", false, "Buffer");

// // having an empty uri for a non embedded image should not be valid
// if (!is_binary && buffer.uri.empty()) {
//     if (err) {
//     (*err) += "'uri' is missing from non binary glTF file buffer.\n";
//     }
// }

// detail::json_const_iterator type;
// if (detail::FindMember(o, "type", type)) {
//     std::string typeStr;
//     if (detail::GetString(detail::GetValue(type), typeStr)) {
//     if (typeStr.compare("arraybuffer") == 0) {
//         // buffer.type = "arraybuffer";
//     }
//     }
// }

// if (is_binary) {
//     // Still binary glTF accepts external dataURI.
//     if (!buffer.uri.empty()) {
//     // First try embedded data URI.
//     if (IsDataURI(buffer.uri)) {
//         std::string mime_type;
//         if (!DecodeDataURI(&buffer.data, mime_type, buffer.uri, byteLength,
//                         true)) {
//         if (err) {
//             (*err) +=
//                 "Failed to decode 'uri' : " + buffer.uri + " in Buffer\n";
//         }
//         return false;
//         }
//     } else {
//         // External .bin file.
//         std::string decoded_uri;
//         if (!uri_cb.decode(buffer.uri, &decoded_uri, uri_cb.user_data)) {
//         return false;
//         }
//         if (!LoadExternalFile(&buffer.data, err, /* warn */ nullptr,
//                             decoded_uri, basedir, /* required */ true,
//                             byteLength, /* checkSize */ true, fs)) {
//         return false;
//         }
//     }
//     } else {
//     // load data from (embedded) binary data

//     if ((bin_size == 0) || (bin_data == nullptr)) {
//         if (err) {
//         (*err) += "Invalid binary data in `Buffer', or GLB with empty BIN chunk.\n";
//         }
//         return false;
//     }

//     if (byteLength > bin_size) {
//         if (err) {
//         std::stringstream ss;
//         ss << "Invalid `byteLength'. Must be equal or less than binary size: "
//                 ~ "`byteLength' = "
//             << byteLength << ", binary size = " << bin_size << std::endl;
//         (*err) += ss.str();
//         }
//         return false;
//     }

//     // Read buffer data
//     buffer.data.resize(static_cast<size_t>(byteLength));
//     memcpy(&(buffer.data.at(0)), bin_data, static_cast<size_t>(byteLength));
//     }

// } else {
//     if (IsDataURI(buffer.uri)) {
//     std::string mime_type;
//     if (!DecodeDataURI(&buffer.data, mime_type, buffer.uri, byteLength,
//                         true)) {
//         if (err) {
//         (*err) += "Failed to decode 'uri' : " + buffer.uri + " in Buffer\n";
//         }
//         return false;
//     }
//     } else {
//     // Assume external .bin file.
//     std::string decoded_uri;
//     if (!uri_cb.decode(buffer.uri, &decoded_uri, uri_cb.user_data)) {
//         return false;
//     }
//     if (!LoadExternalFile(&buffer.data, err, /* warn */ nullptr, decoded_uri,
//                             basedir, /* required */ true, byteLength,
//                             /* checkSize */ true, fs)) {
//         return false;
//     }
//     }
// }

// ParseStringProperty(&buffer.name, err, o, "name", false);

// ParseExtensionsProperty(&buffer.extensions, err, o);
// ParseExtrasProperty(&buffer.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         buffer.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         buffer.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseBufferView(BufferView* bufferView, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// int buffer = -1;
// if (!ParseIntegerProperty(&buffer, err, o, "buffer", true, "BufferView")) {
//     return false;
// }

// size_t byteOffset = 0;
// ParseUnsignedProperty(&byteOffset, err, o, "byteOffset", false);

// size_t byteLength = 1;
// if (!ParseUnsignedProperty(&byteLength, err, o, "byteLength", true,
//                             "BufferView")) {
//     return false;
// }

// size_t byteStride = 0;
// if (!ParseUnsignedProperty(&byteStride, err, o, "byteStride", false)) {
//     // Spec says: When byteStride of referenced bufferView is not defined, it
//     // means that accessor elements are tightly packed, i.e., effective stride
//     // equals the size of the element.
//     // We cannot determine the actual byteStride until Accessor are parsed, thus
//     // set 0(= tightly packed) here(as done in OpenGL's VertexAttribPoiner)
//     byteStride = 0;
// }

// if ((byteStride > 252) || ((byteStride % 4) != 0)) {
//     if (err) {
//     std::stringstream ss;
//     ss << "Invalid `byteStride' value. `byteStride' must be the multiple of "
//             ~ "4 : "
//         << byteStride << std::endl;

//     (*err) += ss.str();
//     }
//     return false;
// }

// int target = 0;
// ParseIntegerProperty(&target, err, o, "target", false);
// if ((target == TINYGLTF_TARGET_ARRAY_BUFFER) ||
//     (target == TINYGLTF_TARGET_ELEMENT_ARRAY_BUFFER)) {
//     // OK
// } else {
//     target = 0;
// }
// bufferView.target = target;

// ParseStringProperty(&bufferView.name, err, o, "name", false);

// ParseExtensionsProperty(&bufferView.extensions, err, o);
// ParseExtrasProperty(&bufferView.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         bufferView.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         bufferView.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// bufferView.buffer = buffer;
// bufferView.byteOffset = byteOffset;
// bufferView.byteLength = byteLength;
// bufferView.byteStride = byteStride;
// return true;
// }

// private bool ParseSparseAccessor(Accessor* accessor, std* err, const(detail) o) {
// accessor.sparse.isSparse = true;

// int count = 0;
// if (!ParseIntegerProperty(&count, err, o, "count", true, "SparseAccessor")) {
//     return false;
// }

// detail::json_const_iterator indices_iterator;
// detail::json_const_iterator values_iterator;
// if (!detail::FindMember(o, "indices", indices_iterator)) {
//     (*err) = "the sparse object of this accessor doesn't have indices";
//     return false;
// }

// if (!detail::FindMember(o, "values", values_iterator)) {
//     (*err) = "the sparse object of this accessor doesn't have values";
//     return false;
// }

// const(detail) indices_obj = GetValue(indices_iterator);
// const(detail) values_obj = GetValue(values_iterator);

// int indices_buffer_view = 0, indices_byte_offset = 0, component_type = 0;
// if (!ParseIntegerProperty(&indices_buffer_view, err, indices_obj,
//                             "bufferView", true, "SparseAccessor")) {
//     return false;
// }
// ParseIntegerProperty(&indices_byte_offset, err, indices_obj, "byteOffset",
//                     false);
// if (!ParseIntegerProperty(&component_type, err, indices_obj, "componentType",
//                             true, "SparseAccessor")) {
//     return false;
// }

// int values_buffer_view = 0, values_byte_offset = 0;
// if (!ParseIntegerProperty(&values_buffer_view, err, values_obj, "bufferView",
//                             true, "SparseAccessor")) {
//     return false;
// }
// ParseIntegerProperty(&values_byte_offset, err, values_obj, "byteOffset",
//                     false);

// accessor.sparse.count = count;
// accessor.sparse.indices.bufferView = indices_buffer_view;
// accessor.sparse.indices.byteOffset = indices_byte_offset;
// accessor.sparse.indices.componentType = component_type;
// accessor.sparse.values.bufferView = values_buffer_view;
// accessor.sparse.values.byteOffset = values_byte_offset;

// return true;
// }

// private bool ParseAccessor(Accessor* accessor, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// int bufferView = -1;
// ParseIntegerProperty(&bufferView, err, o, "bufferView", false, "Accessor");

// size_t byteOffset = 0;
// ParseUnsignedProperty(&byteOffset, err, o, "byteOffset", false, "Accessor");

// bool normalized = false;
// ParseBooleanProperty(&normalized, err, o, "normalized", false, "Accessor");

// size_t componentType = 0;
// if (!ParseUnsignedProperty(&componentType, err, o, "componentType", true,
//                             "Accessor")) {
//     return false;
// }

// size_t count = 0;
// if (!ParseUnsignedProperty(&count, err, o, "count", true, "Accessor")) {
//     return false;
// }

// std::string type;
// if (!ParseStringProperty(&type, err, o, "type", true, "Accessor")) {
//     return false;
// }

// if (type.compare("SCALAR") == 0) {
//     accessor.type = TINYGLTF_TYPE_SCALAR;
// } else if (type.compare("VEC2") == 0) {
//     accessor.type = TINYGLTF_TYPE_VEC2;
// } else if (type.compare("VEC3") == 0) {
//     accessor.type = TINYGLTF_TYPE_VEC3;
// } else if (type.compare("VEC4") == 0) {
//     accessor.type = TINYGLTF_TYPE_VEC4;
// } else if (type.compare("MAT2") == 0) {
//     accessor.type = TINYGLTF_TYPE_MAT2;
// } else if (type.compare("MAT3") == 0) {
//     accessor.type = TINYGLTF_TYPE_MAT3;
// } else if (type.compare("MAT4") == 0) {
//     accessor.type = TINYGLTF_TYPE_MAT4;
// } else {
//     std::stringstream ss;
//     ss << "Unsupported `type` for accessor object. Got \"" << type << "\"\n";
//     if (err) {
//     (*err) += ss.str();
//     }
//     return false;
// }

// ParseStringProperty(&accessor.name, err, o, "name", false);

// accessor.minValues.clear();
// accessor.maxValues.clear();
// ParseNumberArrayProperty(&accessor.minValues, err, o, "min", false,
//                         "Accessor");

// ParseNumberArrayProperty(&accessor.maxValues, err, o, "max", false,
//                         "Accessor");

// accessor.count = count;
// accessor.bufferView = bufferView;
// accessor.byteOffset = byteOffset;
// accessor.normalized = normalized;
// {
//     if (componentType >= TINYGLTF_COMPONENT_TYPE_BYTE &&
//         componentType <= TINYGLTF_COMPONENT_TYPE_DOUBLE) {
//     // OK
//     accessor.componentType = int(componentType);
//     } else {
//     std::stringstream ss;
//     ss << "Invalid `componentType` in accessor. Got " << componentType
//         << "\n";
//     if (err) {
//         (*err) += ss.str();
//     }
//     return false;
//     }
// }

// ParseExtensionsProperty(&(accessor.extensions), err, o);
// ParseExtrasProperty(&(accessor.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         accessor.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         accessor.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// // check if accessor has a "sparse" object:
// detail::json_const_iterator iterator;
// if (detail::FindMember(o, "sparse", iterator)) {
//     // here this accessor has a "sparse" subobject
//     return ParseSparseAccessor(accessor, err, detail::GetValue(iterator));
// }

// return true;
// }

// version (TINYGLTF_ENABLE_DRACO) {

// private void DecodeIndexBuffer(draco* mesh, size_t componentSize, std outBuffer) {
// if (componentSize == 4) {
//     assert(typeof(mesh.face(draco::FaceIndex(0))[0]).sizeof == componentSize);
//     memcpy(outBuffer.data(), &mesh.face(draco::FaceIndex(0))[0],
//         outBuffer.size());
// } else {
//     size_t faceStride = componentSize * 3;
//     for (draco f(); f < mesh.num_faces(); ++f) {
//     const(draco) face = mesh.face(&f);
//     if (componentSize == 2) {
//         ushort[3] indices = [cast(ushort)face[0].value(),
//                             cast(ushort)face[1].value(),
//                             cast(ushort)face[2].value()];
//         memcpy(outBuffer.data() + f.value() * faceStride, &indices[0],
//             faceStride);
//     } else {
//         ubyte[3] indices = [cast(ubyte)face[0].value(),
//                             cast(ubyte)face[1].value(),
//                             cast(ubyte)face[2].value()];
//         memcpy(outBuffer.data() + f.value() * faceStride, &indices[0],
//             faceStride);
//     }
//     }
// }
// }

// template_ <typename T>
// static bool GetAttributeForAllPoints(draco* mesh, const(draco)* pAttribute, std outBuffer) {
// size_t byteOffset = 0;
// T[4] values = 0;
// for (draco i(); i < mesh.num_points(); ++i) {
//     const(draco) val_index = pAttribute.mapped_index(&i);
//     if (!pAttribute.ConvertValue<T>(val_index, pAttribute.num_components(),
//                                     values))
//     return false;

//     memcpy(outBuffer.data() + byteOffset, &values[0],
//         sizeof(T) * pAttribute.num_components());
//     byteOffset += sizeof(T) * pAttribute.num_components();
// }

// return true;
// }

// private bool GetAttributeForAllPoints(uint componentType, draco* mesh, const(draco)* pAttribute, std outBuffer) {
// bool decodeResult = false;
// switch (componentType) {
//     case TINYGLTF_COMPONENT_TYPE_UNSIGNED_BYTE:
//     decodeResult =
//         GetAttributeForAllPoints<uint8_t>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_BYTE:
//     decodeResult =
//         GetAttributeForAllPoints<int8_t>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT:
//     decodeResult =
//         GetAttributeForAllPoints<uint16_t>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_SHORT:
//     decodeResult =
//         GetAttributeForAllPoints<int16_t>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_INT:
//     decodeResult =
//         GetAttributeForAllPoints<int32_t>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_UNSIGNED_INT:
//     decodeResult =
//         GetAttributeForAllPoints<uint32_t>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_FLOAT:
//     decodeResult =
//         GetAttributeForAllPoints<float>(mesh, pAttribute, outBuffer);
//     break;
//     case TINYGLTF_COMPONENT_TYPE_DOUBLE:
//     decodeResult =
//         GetAttributeForAllPoints<double>(mesh, pAttribute, outBuffer);
//     break;
//     default:
//     return false;
// }

// return decodeResult;
// }

// private bool ParseDracoExtension(Primitive* primitive, Model* model, std* err, const(Value) dracoExtensionValue) {
// cast(void)err;
// auto bufferViewValue = dracoExtensionValue.Get("bufferView");
// if (!bufferViewValue.IsInt()) return false;
// auto attributesValue = dracoExtensionValue.Get("attributes");
// if (!attributesValue.IsObject()) return false;

// auto attributesObject = attributesValue.Get<Value;
// int bufferView = bufferViewValue.Get<int>();

// BufferView &view = model.bufferViews[bufferView];
// Buffer &buffer = model.buffers[view.buffer];
// // BufferView has already been decoded
// if (view.dracoDecoded) return true;
// view.dracoDecoded = true;

// const(char)* bufferViewData = reinterpret_cast<const char_ *>(buffer.data.data() + view.byteOffset);
// size_t bufferViewSize = view.byteLength;

// // decode draco
// draco::DecoderBuffer decoderBuffer;
// decoderBuffer.Init(bufferViewData, bufferViewSize);
// draco::Decoder decoder;
// auto decodeResult = decoder.DecodeMeshFromBuffer(&decoderBuffer);
// if (!decodeResult.ok()) {
//     return false;
// }
// const(std) mesh = decodeResult.value();

// // create new bufferView for indices
// if (primitive.indices >= 0) {
//     int componentSize = GetComponentSizeInBytes(
//         model.accessors[primitive.indices].componentType);
//     Buffer decodedIndexBuffer = void;
//     decodedIndexBuffer.data.resize(mesh.num_faces() * 3 * componentSize);

//     DecodeIndexBuffer(mesh.get(), componentSize, decodedIndexBuffer.data);

//     model.buffers.emplace_back(std::move(decodedIndexBuffer));

//     BufferView decodedIndexBufferView = void;
//     decodedIndexBufferView.buffer = int(model.buffers.size() - 1);
//     decodedIndexBufferView.byteLength =
//         int(mesh.num_faces() * 3 * componentSize);
//     decodedIndexBufferView.byteOffset = 0;
//     decodedIndexBufferView.byteStride = 0;
//     decodedIndexBufferView.target = TINYGLTF_TARGET_ARRAY_BUFFER;
//     model.bufferViews.emplace_back(std::move(decodedIndexBufferView));

//     model.accessors[primitive.indices].bufferView =
//         int(model.bufferViews.size() - 1);
//     model.accessors[primitive.indices].count = int(mesh.num_faces() * 3);
// }

// for (auto const(attribute) attributesObject(attribute IsInt());
//     auto_ (primitiveAttribute = primitive.attributes.find(attribute.first)) != 0;
//     if (primitiveAttribute == primitive.attributes.end()) return false;

//     int dracoAttributeIndex = attribute.second.Get<int>(){}
//     auto const(pAttribute) = mesh.GetAttributeByUniqueId(dracoAttributeIndex);
//     auto const(componentType) = model.accessors[primitiveAttribute.second].componentType;

//     // Create a new buffer for this decoded buffer
//     Buffer decodedBuffer = void;
//     size_t bufferSize = mesh.num_points() * pAttribute.num_components() *
//                         GetComponentSizeInBytes(componentType);
//     decodedBuffer.data.resize(bufferSize);

//     if (!GetAttributeForAllPoints(componentType, mesh.get(), pAttribute,
//                                 decodedBuffer.data))
//     return false;

//     model.buffers.emplace_back(std::move(decodedBuffer));

//     BufferView decodedBufferView = void;
//     decodedBufferView.buffer = int(model.buffers.size() - 1);
//     decodedBufferView.byteLength = bufferSize;
//     decodedBufferView.byteOffset = pAttribute.byte_offset();
//     decodedBufferView.byteStride = pAttribute.byte_stride();
//     decodedBufferView.target = primitive.indices >= 0
//                                 ? TINYGLTF_TARGET_ELEMENT_ARRAY_BUFFER
//                                 : TINYGLTF_TARGET_ARRAY_BUFFER;
//     model.bufferViews.emplace_back(std::move(decodedBufferView));

//     model.accessors[primitiveAttribute.second].bufferView =
//         int(model.bufferViews.size() - 1);
//     model.accessors[primitiveAttribute.second].count =
//         int(mesh.num_points());
// }

// return true;
// }
// }

// private bool ParsePrimitive(Primitive* primitive, Model* model, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// int material = -1;
// ParseIntegerProperty(&material, err, o, "material", false);
// primitive.material = material;

// int mode = TINYGLTF_MODE_TRIANGLES;
// ParseIntegerProperty(&mode, err, o, "mode", false);
// primitive.mode = mode;  // Why only triangles were supported ?

// int indices = -1;
// ParseIntegerProperty(&indices, err, o, "indices", false);
// primitive.indices = indices;
// if (!ParseStringIntegerProperty(&primitive.attributes, err, o, "attributes",
//                                 true, "Primitive")) {
//     return false;
// }

// // Look for morph targets
// detail::json_const_iterator targetsObject;
// if (detail::FindMember(o, "targets", targetsObject) &&
//     detail::IsArray(detail::GetValue(targetsObject))) {
//     auto targetsObjectEnd ArrayEnd(detail GetValue(targetsObject));
//     for (detail i = ArrayBegin(detail::GetValue(targetsObject));
//         i != targetsObjectEnd; ++i) {
//     std::map<std::string, int> targetAttribues;

//     const(detail) dict = *i;
//     if (detail::IsObject(dict)) {
//         detail::json_const_iterator dictIt(detail::ObjectBegin(dict));
//         detail::json_const_iterator dictItEnd(detail::ObjectEnd(dict));

//         for (; dictIt != dictItEnd; ++dictIt) {
//         int iVal = void;
//         if (detail::GetInt(detail::GetValue(dictIt), iVal))
//             targetAttribues[detail::GetKey(dictIt)] = iVal;
//         }
//         primitive.targets.emplace_back(std::move(targetAttribues));
//     }
//     }
// }

// ParseExtrasProperty(&(primitive.extras), o);
// ParseExtensionsProperty(&primitive.extensions, err, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         primitive.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         primitive.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// version (TINYGLTF_ENABLE_DRACO) {
// auto dracoExtension = primitive.extensions.find("KHR_draco_mesh_compression");
// if (dracoExtension != primitive.extensions.end()) {
//     ParseDracoExtension(primitive, model, err, dracoExtension.second);
// }
// } else {
// cast(void)model;
// }

// return true;
// }

// private bool ParseMesh(Mesh* mesh, Model* model, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseStringProperty(&mesh.name, err, o, "name", false);

// mesh.primitives.clear();
// detail::json_const_iterator primObject;
// if (detail::FindMember(o, "primitives", primObject) &&
//     detail::IsArray(detail::GetValue(primObject))) {
//     detail::json_const_array_iterator primEnd = detail::ArrayEnd(detail::GetValue(primObject));
//     for (detail i = ArrayBegin(detail::GetValue(primObject));
//         i != primEnd; ++i) {
//     Primitive primitive = void;
//     if (ParsePrimitive(&primitive, model, err, *i,
//                         store_original_json_for_extras_and_extensions)) {
//         // Only add the primitive if the parsing succeeds.
//         mesh.primitives.emplace_back(std::move(primitive));
//     }
//     }
// }

// // Should probably check if has targets and if dimensions fit
// ParseNumberArrayProperty(&mesh.weights, err, o, "weights", false);

// ParseExtensionsProperty(&mesh.extensions, err, o);
// ParseExtrasProperty(&(mesh.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         mesh.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         mesh.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseNode(Node* node, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseStringProperty(&node.name, err, o, "name", false);

// int skin = -1;
// ParseIntegerProperty(&skin, err, o, "skin", false);
// node.skin = skin;

// // Matrix and T/R/S are exclusive
// if (!ParseNumberArrayProperty(&node.matrix, err, o, "matrix", false)) {
//     ParseNumberArrayProperty(&node.rotation, err, o, "rotation", false);
//     ParseNumberArrayProperty(&node.scale, err, o, "scale", false);
//     ParseNumberArrayProperty(&node.translation, err, o, "translation", false);
// }

// int camera = -1;
// ParseIntegerProperty(&camera, err, o, "camera", false);
// node.camera = camera;

// int mesh = -1;
// ParseIntegerProperty(&mesh, err, o, "mesh", false);
// node.mesh = mesh;

// node.children.clear();
// ParseIntegerArrayProperty(&node.children, err, o, "children", false);

// ParseNumberArrayProperty(&node.weights, err, o, "weights", false);

// ParseExtensionsProperty(&node.extensions, err, o);
// ParseExtrasProperty(&(node.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         node.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         node.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParsePbrMetallicRoughness(PbrMetallicRoughness* pbr, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// if (pbr == nullptr) {
//     return false;
// }

// std::vector<double> baseColorFactor;
// if (ParseNumberArrayProperty(&baseColorFactor, err, o, "baseColorFactor",
//                             /* required */ false)) {
//     if (baseColorFactor.size() != 4) {
//     if (err) {
//         (*err) +=
//             "Array length of `baseColorFactor` parameter in "
//             ~ "pbrMetallicRoughness must be 4, but got " +
//             std::to_string(baseColorFactor.size()) + "\n";
//     }
//     return false;
//     }
//     pbr.baseColorFactor = baseColorFactor;
// }

// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "baseColorTexture", it)) {
//     ParseTextureInfo(&pbr.baseColorTexture, err, detail::GetValue(it),
//                     store_original_json_for_extras_and_extensions);
//     }
// }

// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "metallicRoughnessTexture", it)) {
//     ParseTextureInfo(&pbr.metallicRoughnessTexture, err, detail::GetValue(it),
//                     store_original_json_for_extras_and_extensions);
//     }
// }

// ParseNumberProperty(&pbr.metallicFactor, err, o, "metallicFactor", false);
// ParseNumberProperty(&pbr.roughnessFactor, err, o, "roughnessFactor", false);

// ParseExtensionsProperty(&pbr.extensions, err, o);
// ParseExtrasProperty(&pbr.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         pbr.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         pbr.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseMaterial(Material* material, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseStringProperty(&material.name, err, o, "name", /* required */ false);

// if (ParseNumberArrayProperty(&material.emissiveFactor, err, o,
//                             "emissiveFactor",
//                             /* required */ false)) {
//     if (material.emissiveFactor.size() != 3) {
//     if (err) {
//         (*err) +=
//             "Array length of `emissiveFactor` parameter in "
//             ~ "material must be 3, but got " +
//             std::to_string(material.emissiveFactor.size()) + "\n";
//     }
//     return false;
//     }
// } else {
//     // fill with default values
//     material.emissiveFactor = {0.0, 0.0, 0.0};
// }

// ParseStringProperty(&material.alphaMode, err, o, "alphaMode",
//                     /* required */ false);
// ParseNumberProperty(&material.alphaCutoff, err, o, "alphaCutoff",
//                     /* required */ false);
// ParseBooleanProperty(&material.doubleSided, err, o, "doubleSided",
//                     /* required */ false);

// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "pbrMetallicRoughness", it)) {
//     ParsePbrMetallicRoughness(&material.pbrMetallicRoughness, err,
//                                 detail::GetValue(it),
//                                 store_original_json_for_extras_and_extensions);
//     }
// }

// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "normalTexture", it)) {
//     ParseNormalTextureInfo(&material.normalTexture, err, detail::GetValue(it),
//                             store_original_json_for_extras_and_extensions);
//     }
// }

// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "occlusionTexture", it)) {
//     ParseOcclusionTextureInfo(&material.occlusionTexture, err, detail::GetValue(it),
//                                 store_original_json_for_extras_and_extensions);
//     }
// }

// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "emissiveTexture", it)) {
//     ParseTextureInfo(&material.emissiveTexture, err, detail::GetValue(it),
//                     store_original_json_for_extras_and_extensions);
//     }
// }

// // Old code path. For backward compatibility, we still store material values
// // as Parameter. This will create duplicated information for
// // example(pbrMetallicRoughness), but should be negligible in terms of memory
// // consumption.
// // TODO(syoyo): Remove in the next major release.
// material.values.clear();
// material.additionalValues.clear();

// detail::json_const_iterator it(detail::ObjectBegin(o));
// detail::json_const_iterator itEnd(detail::ObjectEnd(o));

// for (; it != itEnd; ++it) {
//     std::string key(detail::GetKey(it));
//     if (key == "pbrMetallicRoughness") {
//     if (detail::IsObject(detail::GetValue(it))) {
//         const(detail) values_object = GetValue(it);

//         detail::json_const_iterator itVal(detail::ObjectBegin(values_object));
//         detail::json_const_iterator itValEnd(detail::ObjectEnd(values_object));

//         for (; itVal != itValEnd; ++itVal) {
//         Parameter param = void;
//         if (ParseParameterProperty(&param, err, values_object, detail::GetKey(itVal),
//                                     false)) {
//             material.values.emplace(detail::GetKey(itVal), std::move(param));
//         }
//         }
//     }
//     } else if (key == "extensions" || key == "extras") {
//     // done later, skip, otherwise poorly parsed contents will be saved in the
//     // parametermap and serialized again later
//     } else {
//     Parameter param = void;
//     if (ParseParameterProperty(&param, err, o, key, false)) {
//         // names of materials have already been parsed. Putting it in this map
//         // doesn't correctly reflect the glTF specification
//         if (key != "name")
//         material.additionalValues.emplace(std::move(key), std::move(param));
//     }
//     }
// }

// material.extensions.clear();
// ParseExtensionsProperty(&material.extensions, err, o);
// ParseExtrasProperty(&(material.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator eit;
//     if (detail::FindMember(o, "extensions", eit)) {
//         material.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator eit;
//     if (detail::FindMember(o, "extras", eit)) {
//         material.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseAnimationChannel(AnimationChannel* channel, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// int samplerIndex = -1;
// int targetIndex = -1;
// if (!ParseIntegerProperty(&samplerIndex, err, o, "sampler", true,
//                             "AnimationChannel")) {
//     if (err) {
//     (*err) += "`sampler` field is missing in animation channels\n";
//     }
//     return false;
// }

// detail::json_const_iterator targetIt;
// if (detail::FindMember(o, "target", targetIt) && detail::IsObject(detail::GetValue(targetIt))) {
//     const(detail) target_object = GetValue(targetIt);

//     ParseIntegerProperty(&targetIndex, err, target_object, "node", false);

//     if (!ParseStringProperty(&channel.target_path, err, target_object, "path",
//                             true)) {
//     if (err) {
//         (*err) += "`path` field is missing in animation.channels.target\n";
//     }
//     return false;
//     }
//     ParseExtensionsProperty(&channel.target_extensions, err, target_object);
//     if (store_original_json_for_extras_and_extensions) {
//     detail::json_const_iterator it;
//     if (detail::FindMember(target_object, "extensions", it)) {
//         channel.target_extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// channel.sampler = samplerIndex;
// channel.target_node = targetIndex;

// ParseExtensionsProperty(&channel.extensions, err, o);
// ParseExtrasProperty(&(channel.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         channel.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         channel.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseAnimation(Animation* animation, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// {
//     detail::json_const_iterator channelsIt;
//     if (detail::FindMember(o, "channels", channelsIt) &&
//         detail::IsArray(detail::GetValue(channelsIt))) {
//     detail::json_const_array_iterator channelEnd = detail::ArrayEnd(detail::GetValue(channelsIt));
//     for (detail i = ArrayBegin(detail::GetValue(channelsIt));
//         i != channelEnd; ++i) {
//         AnimationChannel channel = void;
//         if (ParseAnimationChannel(
//                 &channel, err, *i,
//                 store_original_json_for_extras_and_extensions)) {
//         // Only add the channel if the parsing succeeds.
//         animation.channels.emplace_back(std::move(channel));
//         }
//     }
//     }
// }

// {
//     detail::json_const_iterator samplerIt;
//     if (detail::FindMember(o, "samplers", samplerIt) && detail::IsArray(detail::GetValue(samplerIt))) {
//     const(detail) sampler_array = GetValue(samplerIt);

//     detail::json_const_array_iterator it = detail::ArrayBegin(sampler_array);
//     detail::json_const_array_iterator itEnd = detail::ArrayEnd(sampler_array);

//     for (; it != itEnd; ++it) {
//         const(detail) s = *it;

//         AnimationSampler sampler = void;
//         int inputIndex = -1;
//         int outputIndex = -1;
//         if (!ParseIntegerProperty(&inputIndex, err, s, "input", true)) {
//         if (err) {
//             (*err) += "`input` field is missing in animation.sampler\n";
//         }
//         return false;
//         }
//         ParseStringProperty(&sampler.interpolation, err, s, "interpolation",
//                             false);
//         if (!ParseIntegerProperty(&outputIndex, err, s, "output", true)) {
//         if (err) {
//             (*err) += "`output` field is missing in animation.sampler\n";
//         }
//         return false;
//         }
//         sampler.input = inputIndex;
//         sampler.output = outputIndex;
//         ParseExtensionsProperty(&(sampler.extensions), err, o);
//         ParseExtrasProperty(&(sampler.extras), s);

//         if (store_original_json_for_extras_and_extensions) {
//         {
//             detail::json_const_iterator eit;
//             if (detail::FindMember(o, "extensions", eit)) {
//             sampler.extensions_json_string = detail::JsonToString(detail::GetValue);
//             }
//         }
//         {
//             detail::json_const_iterator eit;
//             if (detail::FindMember(o, "extras", eit)) {
//             sampler.extras_json_string = detail::JsonToString(detail::GetValue);
//             }
//         }
//         }

//         animation.samplers.emplace_back(std::move(sampler));
//     }
//     }
// }

// ParseStringProperty(&animation.name, err, o, "name", false);

// ParseExtensionsProperty(&animation.extensions, err, o);
// ParseExtrasProperty(&(animation.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         animation.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         animation.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseSampler(Sampler* sampler, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseStringProperty(&sampler.name, err, o, "name", false);

// int minFilter = -1;
// int magFilter = -1;
// int wrapS = TINYGLTF_TEXTURE_WRAP_REPEAT;
// int wrapT = TINYGLTF_TEXTURE_WRAP_REPEAT;
// // int wrapR = TINYGLTF_TEXTURE_WRAP_REPEAT;
// ParseIntegerProperty(&minFilter, err, o, "minFilter", false);
// ParseIntegerProperty(&magFilter, err, o, "magFilter", false);
// ParseIntegerProperty(&wrapS, err, o, "wrapS", false);
// ParseIntegerProperty(&wrapT, err, o, "wrapT", false);
// // ParseIntegerProperty(&wrapR, err, o, "wrapR", false);  // tinygltf
// // extension

// // TODO(syoyo): Check the value is allowed one.
// // (e.g. we allow 9728(NEAREST), but don't allow 9727)

// sampler.minFilter = minFilter;
// sampler.magFilter = magFilter;
// sampler.wrapS = wrapS;
// sampler.wrapT = wrapT;
// // sampler->wrapR = wrapR;

// ParseExtensionsProperty(&(sampler.extensions), err, o);
// ParseExtrasProperty(&(sampler.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         sampler.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         sampler.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseSkin(Skin* skin, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseStringProperty(&skin.name, err, o, "name", false, "Skin");

// std::vector<int> joints;
// if (!ParseIntegerArrayProperty(&joints, err, o, "joints", false, "Skin")) {
//     return false;
// }
// skin.joints = std::move(joints);

// int skeleton = -1;
// ParseIntegerProperty(&skeleton, err, o, "skeleton", false, "Skin");
// skin.skeleton = skeleton;

// int invBind = -1;
// ParseIntegerProperty(&invBind, err, o, "inverseBindMatrices", true, "Skin");
// skin.inverseBindMatrices = invBind;

// ParseExtensionsProperty(&(skin.extensions), err, o);
// ParseExtrasProperty(&(skin.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         skin.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         skin.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParsePerspectiveCamera(PerspectiveCamera* camera, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// double yfov = 0.0;
// if (!ParseNumberProperty(&yfov, err, o, "yfov", true, "OrthographicCamera")) {
//     return false;
// }

// double znear = 0.0;
// if (!ParseNumberProperty(&znear, err, o, "znear", true,
//                         "PerspectiveCamera")) {
//     return false;
// }

// double aspectRatio = 0.0;  // = invalid
// ParseNumberProperty(&aspectRatio, err, o, "aspectRatio", false,
//                     "PerspectiveCamera");

// double zfar = 0.0;  // = invalid
// ParseNumberProperty(&zfar, err, o, "zfar", false, "PerspectiveCamera");

// camera.aspectRatio = aspectRatio;
// camera.zfar = zfar;
// camera.yfov = yfov;
// camera.znear = znear;

// ParseExtensionsProperty(&camera.extensions, err, o);
// ParseExtrasProperty(&(camera.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         camera.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         camera.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// // TODO(syoyo): Validate parameter values.

// return true;
// }

// private bool ParseSpotLight(SpotLight* light, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// ParseNumberProperty(&light.innerConeAngle, err, o, "innerConeAngle", false);
// ParseNumberProperty(&light.outerConeAngle, err, o, "outerConeAngle", false);

// ParseExtensionsProperty(&light.extensions, err, o);
// ParseExtrasProperty(&light.extras, o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         light.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         light.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// // TODO(syoyo): Validate parameter values.

// return true;
// }

// private bool ParseOrthographicCamera(OrthographicCamera* camera, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// double xmag = 0.0;
// if (!ParseNumberProperty(&xmag, err, o, "xmag", true, "OrthographicCamera")) {
//     return false;
// }

// double ymag = 0.0;
// if (!ParseNumberProperty(&ymag, err, o, "ymag", true, "OrthographicCamera")) {
//     return false;
// }

// double zfar = 0.0;
// if (!ParseNumberProperty(&zfar, err, o, "zfar", true, "OrthographicCamera")) {
//     return false;
// }

// double znear = 0.0;
// if (!ParseNumberProperty(&znear, err, o, "znear", true,
//                         "OrthographicCamera")) {
//     return false;
// }

// ParseExtensionsProperty(&camera.extensions, err, o);
// ParseExtrasProperty(&(camera.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         camera.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         camera.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// camera.xmag = xmag;
// camera.ymag = ymag;
// camera.zfar = zfar;
// camera.znear = znear;

// // TODO(syoyo): Validate parameter values.

// return true;
// }

// private bool ParseCamera(Camera* camera, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// if (!ParseStringProperty(&camera.type, err, o, "type", true, "Camera")) {
//     return false;
// }

// if (camera.type.compare("orthographic") == 0) {
//     detail::json_const_iterator orthoIt;
//     if (!detail::FindMember(o, "orthographic", orthoIt)) {
//     if (err) {
//         std::stringstream ss;
//         ss << "Orthographic camera description not found." << std::endl;
//         (*err) += ss.str();
//     }
//     return false;
//     }

//     const(detail) v = GetValue(orthoIt);
//     if (!detail::IsObject(v)) {
//     if (err) {
//         std::stringstream ss;
//         ss << "\"orthographic\" is not a JSON object." << std::endl;
//         (*err) += ss.str();
//     }
//     return false;
//     }

//     if (!ParseOrthographicCamera(
//             &camera.orthographic, err, v,
//             store_original_json_for_extras_and_extensions)) {
//     return false;
//     }
// } else if (camera.type.compare("perspective") == 0) {
//     detail::json_const_iterator perspIt;
//     if (!detail::FindMember(o, "perspective", perspIt)) {
//     if (err) {
//         std::stringstream ss;
//         ss << "Perspective camera description not found." << std::endl;
//         (*err) += ss.str();
//     }
//     return false;
//     }

//     const(detail) v = GetValue(perspIt);
//     if (!detail::IsObject(v)) {
//     if (err) {
//         std::stringstream ss;
//         ss << "\"perspective\" is not a JSON object." << std::endl;
//         (*err) += ss.str();
//     }
//     return false;
//     }

//     if (!ParsePerspectiveCamera(
//             &camera.perspective, err, v,
//             store_original_json_for_extras_and_extensions)) {
//     return false;
//     }
// } else {
//     if (err) {
//     std::stringstream ss;
//     ss << "Invalid camera type: \"" << camera.type
//         << "\". Must be \"perspective\" or \"orthographic\"" << std::endl;
//     (*err) += ss.str();
//     }
//     return false;
// }

// ParseStringProperty(&camera.name, err, o, "name", false);

// ParseExtensionsProperty(&camera.extensions, err, o);
// ParseExtrasProperty(&(camera.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         camera.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         camera.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// private bool ParseLight(Light* light, std* err, const(detail) o, bool store_original_json_for_extras_and_extensions) {
// if (!ParseStringProperty(&light.type, err, o, "type", true)) {
//     return false;
// }

// if (light.type == "spot") {
//     detail::json_const_iterator spotIt;
//     if (!detail::FindMember(o, "spot", spotIt)) {
//     if (err) {
//         std::stringstream ss;
//         ss << "Spot light description not found." << std::endl;
//         (*err) += ss.str();
//     }
//     return false;
//     }

//     const(detail) v = GetValue(spotIt);
//     if (!detail::IsObject(v)) {
//     if (err) {
//         std::stringstream ss;
//         ss << "\"spot\" is not a JSON object." << std::endl;
//         (*err) += ss.str();
//     }
//     return false;
//     }

//     if (!ParseSpotLight(&light.spot, err, v,
//                         store_original_json_for_extras_and_extensions)) {
//     return false;
//     }
// }

// ParseStringProperty(&light.name, err, o, "name", false);
// ParseNumberArrayProperty(&light.color, err, o, "color", false);
// ParseNumberProperty(&light.range, err, o, "range", false);
// ParseNumberProperty(&light.intensity, err, o, "intensity", false);
// ParseExtensionsProperty(&light.extensions, err, o);
// ParseExtrasProperty(&(light.extras), o);

// if (store_original_json_for_extras_and_extensions) {
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         light.extensions_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extras", it)) {
//         light.extras_json_string = detail::JsonToString(detail::GetValue);
//     }
//     }
// }

// return true;
// }

// bool LoadFromString(Model* model, std* err, std* warn, const(char)* json_str, uint json_str_length, const(std) base_dir, uint check_sections) {
// if (json_str_length < 4) {
//     if (err) {
//     (*err) = "JSON string too short.\n";
//     }
//     return false;
// }

// detail::JsonDocument v;

// static if ((HasVersion!"__cpp_exceptions" || HasVersion!"__EXCEPTIONS" || \
//     HasVersion!"_CPPUNWIND") &&                               \
//     !HasVersion!"TINYGLTF_NOEXCEPTION") {
// try_ {
//     detail::JsonParse(v, json_str, json_str_length, true);

// } catch (std::exception &e) {
//     if (err) {
//     (*err) = e.what();
//     }
//     return false;
// }
// } else {
// {
//     detail::JsonParse(v, json_str, json_str_length);

//     if (!detail::IsObject(v)) {
//     // Assume parsing was failed.
//     if (err) {
//         (*err) = "Failed to parse JSON object\n";
//     }
//     return false;
//     }
// }
// }

// if (!detail::IsObject(v)) {
//     // root is not an object.
//     if (err) {
//     (*err) = "Root element is not a JSON object\n";
//     }
//     return false;
// }

// {
//     bool version_found = false;
//     detail::json_const_iterator it;
//     if (detail::FindMember(v, "asset", it) && detail::IsObject(detail::GetValue(it))) {
//     auto &itObj = detail::GetValue(it);
//     detail::json_const_iterator version_it;
//     std::string versionStr;
//     if (detail::FindMember(itObj, "version", version_it) &&
//         detail::GetString(detail::GetValue(version_it), versionStr)) {
//         version_found = true;
//     }
//     }
//     if (version_found) {
//     // OK
//     } else if (check_sections & REQUIRE_VERSION) {
//     if (err) {
//         (*err) += "\"asset\" object not found in .gltf or not an object type\n";
//     }
//     return false;
//     }
// }

// // scene is not mandatory.
// // FIXME Maybe a better way to handle it than removing the code

// auto const(IsArrayMemberPresent) _v = void, const = void; char* name {
//     detail::json_const_iterator it;
//     return detail::FindMember(_v, name, it) && detail::IsArray(detail::GetValue(it));
// }{}

// {
//     if ((check_sections & REQUIRE_SCENES) &&
//         !IsArrayMemberPresent(v, "scenes")) {
//     if (err) {
//         (*err) += "\"scenes\" object not found in .gltf or not an array type\n";
//     }
//     return false;
//     }
// }

// {
//     if ((check_sections & REQUIRE_NODES) && !IsArrayMemberPresent(v, "nodes")) {
//     if (err) {
//         (*err) += "\"nodes\" object not found in .gltf\n";
//     }
//     return false;
//     }
// }

// {
//     if ((check_sections & REQUIRE_ACCESSORS) &&
//         !IsArrayMemberPresent(v, "accessors")) {
//     if (err) {
//         (*err) += "\"accessors\" object not found in .gltf\n";
//     }
//     return false;
//     }
// }

// {
//     if ((check_sections & REQUIRE_BUFFERS) &&
//         !IsArrayMemberPresent(v, "buffers")) {
//     if (err) {
//         (*err) += "\"buffers\" object not found in .gltf\n";
//     }
//     return false;
//     }
// }

// {
//     if ((check_sections & REQUIRE_BUFFER_VIEWS) &&
//         !IsArrayMemberPresent(v, "bufferViews")) {
//     if (err) {
//         (*err) += "\"bufferViews\" object not found in .gltf\n";
//     }
//     return false;
//     }
// }

// model.buffers.clear();
// model.bufferViews.clear();
// model.accessors.clear();
// model.meshes.clear();
// model.cameras.clear();
// model.nodes.clear();
// model.extensionsUsed.clear();
// model.extensionsRequired.clear();
// model.extensions.clear();
// model.defaultScene = -1;

// // 1. Parse Asset
// {
//     detail::json_const_iterator it;
//     if (detail::FindMember(v, "asset", it) && detail::IsObject(detail::GetValue(it))) {
//     const(detail) root = GetValue(it);

//     ParseAsset(&model.asset, err, root,
//                 store_original_json_for_extras_and_extensions_);
//     }
// }

// version (TINYGLTF_USE_CPP14) {
// auto const(ForEachInArray) _v, const; char *member,
//                         const auto_ &cb) . bool
// } else {
// // The std::function<> implementation can be less efficient because it will
// // allocate heap when the size of the captured lambda is above 16 bytes with
// // clang and gcc, but it does not require C++14.
// auto const(ForEachInArray) _v, const; char* member; char itm = 0;
//     if (detail::FindMember(_v, member, itm) && detail::IsArray(detail::GetValue(itm))) {
//     const(detail) root = GetValue(itm);
//     auto it ArrayBegin(root);
//     auto end ArrayEnd(root);
//     for (; it != end; ++it) {
//         if (!cb(*it)) return false;
//     }
//     }
//     return true;
// }{}

// // 2. Parse extensionUsed
// {
//     ForEachInArray(v, "extensionsUsed", [&](const detail::json &o) {
//     std::string str;
//     detail::GetString(o, str);
//     model.extensionsUsed.emplace_back(std::move(str));
//     return true;
//     }){}
// }

// {
//     ForEachInArray(v, "extensionsRequired", [&](const detail::json &o) {
//     std::string str;
//     detail::GetString(o, str);
//     model.extensionsRequired.emplace_back(std::move(str));
//     return true;
//     }){}
// }

// // 3. Parse Buffer
// {
//     bool success = ForEachInArray(v, "buffers", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`buffers' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Buffer buffer;
//     if (!ParseBuffer(&buffer, err, o,
//                     store_original_json_for_extras_and_extensions_, &fs,
//                     &uri_cb, base_dir, is_binary_, bin_data_, bin_size_)) {
//         return false;
//     }

//     model.buffers.emplace_back(std::move(buffer));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }
// // 4. Parse BufferView
// {
//     bool success = ForEachInArray(v, "bufferViews", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`bufferViews' does not contain an JSON object.";
//         }
//         return false;
//     }
//     BufferView bufferView;
//     if (!ParseBufferView(&bufferView, err, o,
//                         store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.bufferViews.emplace_back(std::move(bufferView));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 5. Parse Accessor
// {
//     bool success = ForEachInArray(v, "accessors", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`accessors' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Accessor accessor;
//     if (!ParseAccessor(&accessor, err, o,
//                         store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.accessors.emplace_back(std::move(accessor));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 6. Parse Mesh
// {
//     bool success = ForEachInArray(v, "meshes", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`meshes' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Mesh mesh;
//     if (!ParseMesh(&mesh, model, err, o,
//                     store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.meshes.emplace_back(std::move(mesh));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // Assign missing bufferView target types
// // - Look for missing Mesh indices
// // - Look for missing Mesh attributes
// for (auto  meshes(auto primitive primitives);
//         }
//         return false;
//         }

//         auto bufferView =
//             model.accessors[size_t(primitive.indices)].bufferView;
//         if (bufferView < 0 || size_t(bufferView) >= model.bufferViews.size()) {
//         if (err) {
//             (*err) += "accessor[" + std::to_string(primitive.indices) +
//                     "] invalid bufferView";
//         }
//         return false;
//         }

//         model.bufferViews[size_t(bufferView)].target =
//             TINYGLTF_TARGET_ELEMENT_ARRAY_BUFFER;
//         // we could optionally check if accessors' bufferView type is Scalar, as
//         // it should be
//     }

//     for (auto_ &attribute : primitive.attributes) {
//         const auto accessorsIndex = size_t(attribute.second);
//         if (accessorsIndex < model.accessors.size()) {
//         const auto bufferView = model.accessors[accessorsIndex].bufferView;
//         // bufferView could be null(-1) for sparse morph target
//         if (bufferView >= 0 && bufferView < cast(int)model.bufferViews.size()) {
//             model.bufferViews[size_t(bufferView)].target =
//                 TINYGLTF_TARGET_ARRAY_BUFFER;
//         }
//         }
//     }

//     for (auto_ &target : primitive.targets) {
//         for (auto_ &attribute : target) {
//         const auto accessorsIndex = size_t(attribute.second);
//         if (accessorsIndex < model.accessors.size()) {
//             const auto bufferView = model.accessors[accessorsIndex].bufferView;
//             // bufferView could be null(-1) for sparse morph target
//             if (bufferView >= 0 && bufferView < cast(int)model.bufferViews.size()) {
//             model.bufferViews[size_t(bufferView)].target =
//                 TINYGLTF_TARGET_ARRAY_BUFFER;
//             }
//         }
//         }
//     }
//     }
// }

// // 7. Parse Node
// {
//     bool success = ForEachInArray(v, "nodes", [&](const detail::json &o) {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`nodes' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Node node;
//     if (!ParseNode(&node, err, o,
//                     store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.nodes.emplace_back(std::move(node));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }}
// }

// // 8. Parse scenes.
// {
//     bool success = ForEachInArray(v, "scenes", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`scenes' does not contain an JSON object.";
//         }
//         return false;
//     }
//     std::vector<int> nodes;
//     ParseIntegerArrayProperty(&nodes, err, o, "nodes", false);

//     Scene scene;
//     scene.nodes = std::move(nodes);

//     ParseStringProperty(&scene.name, err, o, "name", false);

//     ParseExtensionsProperty(&scene.extensions, err, o);
//     ParseExtrasProperty(&scene.extras, o);

//     if (store_original_json_for_extras_and_extensions_) {
//         {
//         detail::json_const_iterator it;
//         if (detail::FindMember(o, "extensions", it)) {
//             scene.extensions_json_string = detail::JsonToString(detail::GetValue);
//         }
//         }
//         {
//         detail::json_const_iterator it;
//         if (detail::FindMember(o, "extras", it)) {
//             scene.extras_json_string = detail::JsonToString(detail::GetValue);
//         }
//         }
//     }

//     model.scenes.emplace_back(std::move(scene));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 9. Parse default scenes.
// {
//     detail::json_const_iterator rootIt;
//     int iVal;
//     if (detail::FindMember(v, "scene", rootIt) && detail::GetInt(detail::GetValue(rootIt), iVal)) {
//     model.defaultScene = iVal;
//     }
// }

// // 10. Parse Material
// {
//     bool success = ForEachInArray(v, "materials", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`materials' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Material material;
//     ParseStringProperty(&material.name, err, o, "name", false);

//     if (!ParseMaterial(&material, err, o,
//                         store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.materials.emplace_back(std::move(material));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 11. Parse Image
// void* load_image_user_data {nullptr};

// LoadImageDataOption load_image_option = void;

// if (user_image_loader_) {
//     // Use user supplied pointer
//     load_image_user_data = load_image_user_data_;
// } else {
//     load_image_option.preserve_channels = preserve_image_channels_;
//     load_image_user_data = reinterpret_cast<void *>(&load_image_option);
// }

// {
//     int idx = 0;
//     bool success = ForEachInArray(v, "images", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "image[" + std::to_string(idx) + "] is not a JSON object.";
//         }
//         return false;
//     }
//     Image image = void;
//     if (!ParseImage(&image, idx, err, warn, o,
//                     store_original_json_for_extras_and_extensions_, base_dir,
//                     &fs, &uri_cb, &this_.LoadImageData,
//                     load_image_user_data)) {
//         return false;
//     }

//     if (image.bufferView != -1) {
//         // Load image from the buffer view.
//         if (size_t(image.bufferView) >= model.bufferViews.size()) {
//         if (err) {
//             std::stringstream ss;
//             ss << "image[" << idx << "] bufferView \"" << image.bufferView
//             << "\" not found in the scene." << std::endl;
//             (*err) += ss.str();
//         }
//         return false;
//         }

//         const(BufferView) bufferView = model.bufferViews[size_t(image.bufferView)];
//         if (size_t(bufferView.buffer) >= model.buffers.size()) {
//         if (err) {
//             std::stringstream ss;
//             ss << "image[" << idx << "] buffer \"" << bufferView.buffer
//             << "\" not found in the scene." << std::endl;
//             (*err) += ss.str();
//         }
//         return false;
//         }
//         const(Buffer) buffer = model.buffers[size_t(bufferView.buffer)];

//         if (*LoadImageData == nullptr) {
//         if (err) {
//             (*err) += "No LoadImageData callback specified.\n";
//         }
//         return false;
//         }
//         bool ret = LoadImageData(
//             &image, idx, err, warn, image.width, image.height,
//             &buffer.data[bufferView.byteOffset],
//             static_cast<int>(bufferView.byteLength), load_image_user_data);
//         if (!ret) {
//         return false;
//         }
//     }

//     model.images.emplace_back(std::move(image));
//     ++idx;
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 12. Parse Texture
// {
//     bool success = ForEachInArray(v, "textures", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`textures' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Texture texture = void;
//     if (!ParseTexture(&texture, err, o,
//                         store_original_json_for_extras_and_extensions_,
//                         base_dir)) {
//         return false;
//     }

//     model.textures.emplace_back(std::move(texture));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 13. Parse Animation
// {
//     bool success = ForEachInArray(v, "animations", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`animations' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Animation animation = void;
//     if (!ParseAnimation(&animation, err, o,
//                         store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.animations.emplace_back(std::move(animation));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 14. Parse Skin
// {
//     bool success = ForEachInArray(v, "skins", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`skins' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Skin skin = void;
//     if (!ParseSkin(&skin, err, o,
//                     store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.skins.emplace_back(std::move(skin));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 15. Parse Sampler
// {
//     bool success = ForEachInArray(v, "samplers", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`samplers' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Sampler sampler = void;
//     if (!ParseSampler(&sampler, err, o,
//                         store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.samplers.emplace_back(std::move(sampler));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 16. Parse Camera
// {
//     bool success = ForEachInArray(v, "cameras", [&](const detail::json &o); {
//     if (!detail::IsObject(o)) {
//         if (err) {
//         (*err) += "`cameras' does not contain an JSON object.";
//         }
//         return false;
//     }
//     Camera camera = void;
//     if (!ParseCamera(&camera, err, o,
//                     store_original_json_for_extras_and_extensions_)) {
//         return false;
//     }

//     model.cameras.emplace_back(std::move(camera));
//     return true;
//     }){}

//     if (!success) {
//     return false;
//     }
// }

// // 17. Parse Extensions
// ParseExtensionsProperty(&model.extensions, err, v);

// // 18. Specific extension implementations
// {
//     detail::json_const_iterator rootIt;
//     if (detail::FindMember(v, "extensions", rootIt) && detail::IsObject(detail::GetValue(rootIt))) {
//     const(detail) root = GetValue(rootIt);

//     detail::json_const_iterator it(detail::ObjectBegin(root));
//     detail::json_const_iterator itEnd(detail::ObjectEnd(root));
//     for (; it != itEnd; ++it) {
//         // parse KHR_lights_punctual extension
//         std::string key(detail::GetKey(it));
//         if ((key == "KHR_lights_punctual") && detail::IsObject(detail::GetValue(it))) {
//         const(detail) object = GetValue(it);
//         detail::json_const_iterator itLight;
//         if (detail::FindMember(object, "lights", itLight)) {
//             const(detail) lights = GetValue(itLight);
//             if (!detail::IsArray(lights)) {
//             continue;
//             }

//             auto  = void;
//             auto  = void;
//             for (; arrayIt != arrayItEnd; ++arrayIt) {
//             Light light = void;
//             if (!ParseLight(&light, err, *arrayIt,
//                             store_original_json_for_extras_and_extensions_)) {
//                 return false;
//             }
//             model.lights.emplace_back(std::move(light));
//             }
//         }
//         }
//     }
//     }
// }

// // 19. Parse Extras
// ParseExtrasProperty(&model.extras, v);

// if (store_original_json_for_extras_and_extensions_) {
//     model.extras_json_string = detail::JsonToString(v["extras"]);
//     model.extensions_json_string = detail::JsonToString(v["extensions"]);
// }

// return true;
// }

// bool LoadASCIIFromString(Model* model, std* err, std* warn, const(char)* str, uint length, const(std) base_dir, uint check_sections) {
// is_binary_ = false;
// bin_data_ = nullptr;
// bin_size_ = 0;

// return LoadFromString(model, err, warn, str, length, base_dir,
//                         check_sections);
// }

// bool LoadASCIIFromFile(Model* model, std* err, std* warn, const(std) filename, uint check_sections) {
// std::stringstream ss;

// if (fs.ReadWholeFile == nullptr) {
//     // Programmer error, assert() ?
//     ss << "Failed to read file: " << filename
//     << ": one or more FS callback not set" << std::endl;
//     if (err) {
//     (*err) = ss.str();
//     }
//     return false;
// }

// std::vector<unsigned char_> data;
// std::string fileerr;
// bool fileread = fs.ReadWholeFile(&data, &fileerr, filename, fs.user_data);
// if (!fileread) {
//     ss << "Failed to read file: " << filename << ": " << fileerr << std::endl;
//     if (err) {
//     (*err) = ss.str();
//     }
//     return false;
// }

// size_t sz = data.size();
// if (sz == 0) {
//     if (err) {
//     (*err) = "Empty file.";
//     }
//     return false;
// }

// std::string basedir = GetBaseDir(filename);

// bool ret = LoadASCIIFromString(
//     model, err, warn, reinterpret_cast<const char_ *>(&data.at(0)),
//     static_cast<unsigned int>(data.size()), basedir, check_sections);

// return ret;
// }

// bool LoadBinaryFromMemory(Model* model, std* err, std* warn, const(ubyte)* bytes, uint size, const(std) base_dir, uint check_sections) {
// if (size < 20) {
//     if (err) {
//     (*err) = "Too short data size for glTF Binary.";
//     }
//     return false;
// }

// if (bytes[0] == 'g' && bytes[1] == 'l' && bytes[2] == 'T' &&
//     bytes[3] == 'F') {
//     // ok
// } else {
//     if (err) {
//     (*err) = "Invalid magic.";
//     }
//     return false;
// }

// uint version_ = void;       // 4 bytes
// uint length = void;        // 4 bytes
// uint chunk0_length = void;  // 4 bytes
// uint chunk0_format = void;  // 4 bytes;

// memcpy(&version_, bytes + 4, 4);
// swap4(&version_);
// memcpy(&length, bytes + 8, 4);
// swap4(&length);
// memcpy(&chunk0_length, bytes + 12, 4); // JSON data length
// swap4(&chunk0_length);
// memcpy(&chunk0_format, bytes + 16, 4);
// swap4(&chunk0_format);

// // https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout
// //
// // In case the Bin buffer is not present, the size is exactly 20 + size of
// // JSON contents,
// // so use "greater than" operator.
// //
// // https://github.com/syoyo/tinygltf/issues/372
// // Use 64bit uint to avoid integer overflow.
// ulong header_and_json_size = 20uLL + uint64_t(chunk0_length);

// if (header_and_json_size > std::numeric_limits<uint32_t>::max()) {
//     // Do not allow 4GB or more GLB data.
// (*err) = "Invalid glTF binary. GLB data exceeds 4GB.";
// }

// if ((header_and_json_size > uint64_t(size)) || (chunk0_length < 1) || (length > size) ||
//     (header_and_json_size > uint64_t(length)) ||
//     (chunk0_format != 0x4E4F534A)) {  // 0x4E4F534A = JSON format.
//     if (err) {
//     (*err) = "Invalid glTF binary.";
//     }
//     return false;
// }

// // Padding check
// // The start and the end of each chunk must be aligned to a 4-byte boundary.
// // No padding check for chunk0 start since its 4byte-boundary is ensured.
// if ((header_and_json_size % 4) != 0) {
//     if (err) {
//     (*err) = "JSON Chunk end does not aligned to a 4-byte boundary.";
//     }
// }

// //std::cout << "header_and_json_size = " << header_and_json_size << "\n";
// //std::cout << "length = " << length << "\n";

// // Chunk1(BIN) data
// // The spec says: When the binary buffer is empty or when it is stored by other means, this chunk SHOULD be omitted.
// // So when header + JSON data == binary size, Chunk1 is omitted.
// if (header_and_json_size == uint64_t(length)) {

//     bin_data_ = nullptr;
//     bin_size_ = 0;
// } else {
//     // Read Chunk1 info(BIN data)
//     // At least Chunk1 should have 12 bytes(8 bytes(header) + 4 bytes(bin payload could be 1~3 bytes, but need to be aligned to 4 bytes)
//     if ((header_and_json_size + 12uLL) > uint64_t(length)) {
//     if (err) {
//         (*err) = "Insufficient storage space for Chunk1(BIN data). At least Chunk1 Must have 4 bytes or more bytes, but got " + std::to_string((header_and_json_size + 12uLL) - uint64_t(length)) + ".\n";
//     }
//     return false;
//     }

//     uint chunk1_length = void;  // 4 bytes
//     uint chunk1_format = void;  // 4 bytes;
//     memcpy(&chunk1_length, bytes + header_and_json_size, 4); // JSON data length
//     swap4(&chunk1_length);
//     memcpy(&chunk1_format, bytes + header_and_json_size + 4, 4);
//     swap4(&chunk1_format);

//     //std::cout << "chunk1_length = " << chunk1_length << "\n";

//     if (chunk1_length < 4) {
//     if (err) {
//         (*err) = "Insufficient Chunk1(BIN) data size.";
//     }
//     return false;
//     }

//     if ((chunk1_length % 4) != 0) {
//     if (err) {
//         (*err) = "BIN Chunk end does not aligned to a 4-byte boundary.";
//     }
//     return false;
//     }

//     if (uint64_t(chunk1_length) + header_and_json_size > uint64_t(length)) {
//     if (err) {
//         (*err) = "BIN Chunk data length exceeds the GLB size.";
//     }
//     return false;
//     }

//     if (chunk1_format != 0x004e4942) {
//     if (err) {
//         (*err) = "Invalid type for chunk1 data.";
//     }
//     return false;
//     }

//     //std::cout << "chunk1_length = " << chunk1_length << "\n";

//     bin_data_ = bytes + header_and_json_size +
//                 8;  // 4 bytes (bin_buffer_length) + 4 bytes(bin_buffer_format)

//     bin_size_ = size_t(chunk1_length);
// }

// // Extract JSON string.
// std::string jsonString(reinterpret_cast<const char_ *>(&bytes[20]),
//                         chunk0_length);

// is_binary_ = true;

// bool ret = LoadFromString(model, err, warn,
//                             reinterpret_cast<const char_ *>(&bytes[20]),
//                             chunk0_length, base_dir, check_sections);
// if (!ret) {
//     return ret;
// }

// return true;
// }

// bool LoadBinaryFromFile(Model* model, std* err, std* warn, const(std) filename, uint check_sections) {
// std::stringstream ss;

// if (fs.ReadWholeFile == nullptr) {
//     // Programmer error, assert() ?
//     ss << "Failed to read file: " << filename
//     << ": one or more FS callback not set" << std::endl;
//     if (err) {
//     (*err) = ss.str();
//     }
//     return false;
// }

// std::vector<unsigned char_> data;
// std::string fileerr;
// bool fileread = fs.ReadWholeFile(&data, &fileerr, filename, fs.user_data);
// if (!fileread) {
//     ss << "Failed to read file: " << filename << ": " << fileerr << std::endl;
//     if (err) {
//     (*err) = ss.str();
//     }
//     return false;
// }

// std::string basedir = GetBaseDir(filename);

// bool ret = LoadBinaryFromMemory(model, err, warn, &data.at(0),
//                                 static_cast<unsigned int>(data.size()),
//                                 basedir, check_sections);

// return ret;
// }

// ///////////////////////
// // GLTF Serialization
// ///////////////////////
// namespace detail {
// detail::json JsonFromString(const char_ *s) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return detail::json(s, detail::GetAllocator());
// } else {
// return detail::json(s);
// }
// }

// void JsonAssign(detail dest, const(detail) src) {
// version (TINYGLTF_USE_RAPIDJSON) {
// dest.CopyFrom(src, detail::GetAllocator());
// } else {
// dest = src;
// }
// }

// void JsonAddMember(detail o, const(char)* key, detail value) {
// version (TINYGLTF_USE_RAPIDJSON) {
// if (!o.IsObject()) {
//     o.SetObject();
// }
// o.AddMember(detail::json(key, detail::GetAllocator()), std::move(value), detail::GetAllocator());
// } else {
// o[key] = std::move(value);
// }
// }

// void JsonPushBack(detail o, detail value) {
// version (TINYGLTF_USE_RAPIDJSON) {
// o.PushBack(std::move(value), detail::GetAllocator());
// } else {
// o.push_back(std::move(value));
// }
// }

// bool JsonIsNull(const(detail) o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// return o.IsNull();
// } else {
// return o.is_null();
// }
// }

// void JsonSetObject(detail o) {
// version (TINYGLTF_USE_RAPIDJSON) {
// o.SetObject();
// } else {
// o = o.object({});
// }
// }

// void JsonReserveArray(detail o, size_t s) {
// version (TINYGLTF_USE_RAPIDJSON) {
// o.SetArray();
// o.Reserve(static_cast<rapidjson::SizeType>(s), detail::GetAllocator());
// }
// cast(void)(o);
// cast(void)(s);
// }
// }  // namespace

// // typedef std::pair<std::string, detail::json> json_object_pair;

// template_ <typename T>
// static void SerializeNumberProperty(const(std) key, T number, detail obj) {
// // obj.insert(
// //    json_object_pair(key, detail::json(static_cast<double>(number))));
// // obj[key] = static_cast<double>(number);
// detail::JsonAddMember(obj, key.c_str(), detail::json(number));
// }

// version (TINYGLTF_USE_RAPIDJSON) {
// template_ <>
// void SerializeNumberProperty(const(std) key, size_t number, detail obj) {
// detail::JsonAddMember(obj, key.c_str(), detail::json(static_cast<uint64_t>(number)));
// }
// }

// template_ <typename T>
// static void SerializeNumberArrayProperty(const(std) key, const(std) value, detail obj) {
// if (value.empty()) return;

// detail::json ary;
// detail::JsonReserveArray(ary, value.size());
// for (auto const(s) JsonPushBack(ary, detail json(s));
// }
// detail::JsonAddMember(obj, key.c_str(), std::move(ary));
// }

// private void SerializeStringProperty(const(std) key, const(std) value, detail obj) {
// detail::JsonAddMember(obj, key.c_str(), detail::JsonFromString(value.c_str()));
// }

// private void SerializeStringArrayProperty(const(std) key, const(std) value, detail obj) {
// detail::json ary;
// detail::JsonReserveArray(ary, value.size());
// for (auto s JsonPushBack(ary, detail JsonFromString(s c_str()));
// }
// detail::JsonAddMember(obj, key.c_str(), std::move(ary));
// }

// static bool ValueToJson(const(Value) value, detail* ret) {
// detail::json obj;
// #ifdef TINYGLTF_USE_RAPIDJSON
// switch (value.Type()) {
//     case REAL_TYPE:
//     obj.SetDouble(value.Get<double>());
//     break;
//     case INT_TYPE:
//     obj.SetInt(value.Get<int>());
//     break;
//     case BOOL_TYPE:
//     obj.SetBool(value.Get<bool_>());
//     break;
//     case STRING_TYPE:
//     obj.SetString(value.Get<std::string>().c_str(), detail::GetAllocator());
//     break;
//     case ARRAY_TYPE: {
//     obj.SetArray();
//     obj.Reserve(static_cast<rapidjson::SizeType>(value.ArrayLen()),
//                 detail::GetAllocator());
//     for (uint i = 0; i < value.ArrayLen(); ++i) {
//         Value elementValue = value.Get(int(i));
//         detail::json elementJson;
//         if (ValueToJson(value.Get(int(i)), &elementJson))
//         obj.PushBack(std::move(elementJson), detail::GetAllocator());
//     }
//     break;
//     }
//     case BINARY_TYPE:
//     // TODO
//     // obj = detail::json(value.Get<std::vector<unsigned char>>());
//     return false;
//     break;
//     case OBJECT_TYPE: {
//     obj.SetObject();
//     Value::Object objMap = value.Get<Value::Object>();
//     for (auto it elementJson;
//         if (ValueToJson(it.second, &elementJson)) {
//         obj.AddMember(detail::json(it.first.c_str(), detail::GetAllocator()),
//                         std::move(elementJson), detail::GetAllocator());
//         }
//     }
//     break;
//     }
//     case NULL_TYPE:
//     default:
//     return false;
// }
// } else {
// switch (value.Type()) {
//     case REAL_TYPE:
//     obj = detail::json(value.Get<double>());
//     break;
//     case INT_TYPE:
//     obj = detail::json(value.Get<int>());
//     break;
//     case BOOL_TYPE:
//     obj = detail::json(value.Get<bool_>());
//     break;
//     case STRING_TYPE:
//     obj = detail::json(value.Get<std::string>());
//     break;
//     case ARRAY_TYPE: {
//     for (uint i = 0; i < value.ArrayLen(); ++i) {
//         Value elementValue = value.Get(int(i));
//         detail::json elementJson;
//         if (ValueToJson(value.Get(int(i)), &elementJson))
//         obj.push_back(elementJson);
//     }
//     break;
//     }
//     case BINARY_TYPE:
//     // TODO
//     // obj = json(value.Get<std::vector<unsigned char>>());
//     return false;
//     break;
//     case OBJECT_TYPE: {
//     Value::Object objMap = value.Get<Value::Object>();
//     for (auto it elementJson;
//         if (ValueToJson(it.second, &elementJson)) obj[it.first] = elementJson;
//     }
//     break;
//     }
//     case NULL_TYPE:
//     default:
//     return false;
// }
// //! #endif
// if (ret) *ret = std::move(obj);
// return true;
// }

// private void SerializeValue(const(std) key, const(Value) value, detail obj) {
// detail::json ret;
// if (ValueToJson(value, &ret)) {
//     detail::JsonAddMember(obj, key.c_str(), std::move(ret));
// }
// }

// private void SerializeGltfBufferData(ubyte data, detail o) {
// std::string header = "data:application/octet-stream;base64,";
// if (data.size() > 0) {
//     std::string encodedData =
//         base64_encode(&data[0], static_cast<unsigned int>(data.size()));
//     SerializeStringProperty("uri", header + encodedData, o);
// } else {
//     // Issue #229
//     // size 0 is allowed. Just emit mime header.
//     SerializeStringProperty("uri", header, o);
// }
// }

// private bool SerializeGltfBufferData(ubyte data, const(std) binFilename) {
// version (Windows) {
// version (__GLIBCXX__) {  // mingw
// int file_descriptor = _wopen(UTF8ToWchar(binFilename).c_str(),
//                             _O_CREAT | _O_WRONLY | _O_TRUNC | _O_BINARY);
// __gnu_cxx::stdio_filebuf<char_> wfile_buf(
//     file_descriptor, std::ios_base::out_ | std::ios_base::binary);
// std::ostream output(&wfile_buf);
// if (!wfile_buf.is_open()) return false;
// } else version (_MSC_VER) {
// std::ofstream output(UTF8ToWchar(binFilename).c_str(), std::ofstream::binary);
// if (!output.is_open()) return false;
// } else {
// std::ofstream output(binFilename.c_str(), std::ofstream::binary);
// if (!output.is_open()) return false;
// }
// } else {
// std::ofstream output(binFilename.c_str(), std::ofstream::binary);
// if (!output.is_open()) return false;
// }
// if (data.size() > 0) {
//     output.write(reinterpret_cast<const char_ *>(&data[0]),
//                 std::streamsize(data.size()));
// } else {
//     // Issue #229
//     // size 0 will be still valid buffer data.
//     // write empty file.
// }
// return true;
// }

// version (none) {  // FIXME(syoyo): not used. will be removed in the future release.
// private void SerializeParameterMap(ParameterMap param, detail o) {
// for (ParameterMap paramIt = param.begin(); paramIt != param.end();
//     ++paramIt) {
//     if (paramIt.second.number_array.size()) {
//     SerializeNumberArrayProperty<double>(paramIt.first,
//                                         paramIt.second.number_array, o);
//     } else if (paramIt.second.json_double_value.size()) {
//     detail::json json_double_value;
//     for (std string = void, it = paramIt.second.json_double_value.begin();
//         it != paramIt.second.json_double_value.end(); ++it) {
//         if (it.first == "index") {
//         json_double_value[it.first] = paramIt.second.TextureIndex();
//         } else {
//         json_double_value[it.first] = it.second;
//         }
//     }

//     o[paramIt.first] = json_double_value;
//     } else if (!paramIt.second.string_value.empty()) {
//     SerializeStringProperty(paramIt.first, paramIt.second.string_value, o);
//     } else if (paramIt.second.has_number_value) {
//     o[paramIt.first] = paramIt.second.number_value;
//     } else {
//     o[paramIt.first] = paramIt.second.bool_value;
//     }
// }
// }
// }

// private void SerializeExtensionMap(const(ExtensionMap) extensions, detail o) {
// if (!extensions.size()) return;

// detail::json extMap;
// for (ExtensionMap extIt = extensions.begin();
//     extIt != extensions.end(); ++extIt) {
//     // Allow an empty object for extension(#97)
//     detail::json ret;
//     bool isNull = true;
//     if (ValueToJson(extIt.second, &ret)) {
//     isNull = detail::JsonIsNull(ret);
//     detail::JsonAddMember(extMap, extIt.first.c_str(), std::move(ret));
//     }
//     if (isNull) {
//     if (!(extIt.first.empty())) {  // name should not be empty, but for sure
//         // create empty object so that an extension name is still included in
//         // json.
//         detail::json empty;
//         detail::JsonSetObject(empty);
//         detail::JsonAddMember(extMap, extIt.first.c_str(), std::move(empty));
//     }
//     }
// }
// detail::JsonAddMember(o, "extensions", std::move(extMap));
// }

// private void SerializeGltfAccessor(const(Accessor) accessor, detail o) {
// if (accessor.bufferView >= 0)
//     SerializeNumberProperty<int>("bufferView", accessor.bufferView, o);

// if (accessor.byteOffset != 0)
//     SerializeNumberProperty<int>("byteOffset", int(accessor.byteOffset), o);

// SerializeNumberProperty<int>("componentType", accessor.componentType, o);
// SerializeNumberProperty<size_t>("count", accessor.count, o);

// if ((accessor.componentType == TINYGLTF_COMPONENT_TYPE_FLOAT) ||
//     (accessor.componentType == TINYGLTF_COMPONENT_TYPE_DOUBLE)) {
//     SerializeNumberArrayProperty<double>("min", accessor.minValues, o);
//     SerializeNumberArrayProperty<double>("max", accessor.maxValues, o);
// } else {
//     // Issue #301. Serialize as integer.
//     // Assume int value is within [-2**31-1, 2**31-1]
//     {
//     std::vector<int> values;
//     std::transform(accessor.minValues.begin(), accessor.minValues.end(),
//                     std::back_inserter(values),
//                     [](double v) { return static_cast<int>(v); }){}

//     SerializeNumberArrayProperty<int>("min", values, o);
//     }

//     {
//     std::vector<int> values;
//     std::transform(accessor.maxValues.begin(), accessor.maxValues.end(),
//                     std::back_inserter(values),
//                     [](double v) { return static_cast<int>(v); }){}

//     SerializeNumberArrayProperty<int>("max", values, o);
//     }
// }

// if (accessor.normalized)
//     SerializeValue("normalized", Value(accessor.normalized), o);
// std::string type;
// switch (accessor.type) {
//     case TINYGLTF_TYPE_SCALAR:
//     type = "SCALAR";
//     break;
//     case TINYGLTF_TYPE_VEC2:
//     type = "VEC2";
//     break;
//     case TINYGLTF_TYPE_VEC3:
//     type = "VEC3";
//     break;
//     case TINYGLTF_TYPE_VEC4:
//     type = "VEC4";
//     break;
//     case TINYGLTF_TYPE_MAT2:
//     type = "MAT2";
//     break;
//     case TINYGLTF_TYPE_MAT3:
//     type = "MAT3";
//     break;
//     case TINYGLTF_TYPE_MAT4:
//     type = "MAT4";
//     break;
// default: break;}

// SerializeStringProperty("type", type, o);
// if (!accessor.name.empty()) SerializeStringProperty("name", accessor.name, o);

// if (accessor.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", accessor.extras, o);
// }

// // sparse
// if (accessor.sparse.isSparse)
// {
//     detail::json sparse;
//     SerializeNumberProperty<int>("count", accessor.sparse.count, sparse);
//     {
//         detail::json indices;
//         SerializeNumberProperty<int>("bufferView", accessor.sparse.indices.bufferView, indices);
//         SerializeNumberProperty<int>("byteOffset", accessor.sparse.indices.byteOffset, indices);
//         SerializeNumberProperty<int>("componentType", accessor.sparse.indices.componentType, indices);
//         detail::JsonAddMember(sparse, "indices", std::move(indices));
//     }
//     {
//         detail::json values;
//         SerializeNumberProperty<int>("bufferView", accessor.sparse.values.bufferView, values);
//         SerializeNumberProperty<int>("byteOffset", accessor.sparse.values.byteOffset, values);
//         detail::JsonAddMember(sparse, "values", std::move(values));
//     }
//     detail::JsonAddMember(o, "sparse", std::move(sparse));
// }
// }

// private void SerializeGltfAnimationChannel(const(AnimationChannel) channel, detail o) {
// SerializeNumberProperty("sampler", channel.sampler, o);
// {
//     detail::json target;

//     if (channel.target_node > 0) {
//     SerializeNumberProperty("node", channel.target_node, target);
//     }

//     SerializeStringProperty("path", channel.target_path, target);

//     SerializeExtensionMap(channel.target_extensions, target);

//     detail::JsonAddMember(o, "target", std::move(target));
// }

// if (channel.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", channel.extras, o);
// }

// SerializeExtensionMap(channel.extensions, o);
// }

// private void SerializeGltfAnimationSampler(const(AnimationSampler) sampler, detail o) {
// SerializeNumberProperty("input", sampler.input, o);
// SerializeNumberProperty("output", sampler.output, o);
// SerializeStringProperty("interpolation", sampler.interpolation, o);

// if (sampler.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", sampler.extras, o);
// }
// }

// private void SerializeGltfAnimation(const(Animation) animation, detail o) {
// if (!animation.name.empty())
//     SerializeStringProperty("name", animation.name, o);

// {
//     detail::json channels;
//     detail::JsonReserveArray(channels, animation.channels.size());
//     for (uint i = 0; i < animation.channels.size(); ++i) {
//     detail::json channel;
//     AnimationChannel gltfChannel = animation.channels[i];
//     SerializeGltfAnimationChannel(gltfChannel, channel);
//     detail::JsonPushBack(channels, std::move(channel));
//     }

//     detail::JsonAddMember(o, "channels", std::move(channels));
// }

// {
//     detail::json samplers;
//     detail::JsonReserveArray(samplers, animation.samplers.size());
//     for (uint i = 0; i < animation.samplers.size(); ++i) {
//     detail::json sampler;
//     AnimationSampler gltfSampler = animation.samplers[i];
//     SerializeGltfAnimationSampler(gltfSampler, sampler);
//     detail::JsonPushBack(samplers, std::move(sampler));
//     }
//     detail::JsonAddMember(o, "samplers", std::move(samplers));
// }

// if (animation.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", animation.extras, o);
// }

// SerializeExtensionMap(animation.extensions, o);
// }

// private void SerializeGltfAsset(const(Asset) asset, detail o) {
// if (!asset.generator.empty()) {
//     SerializeStringProperty("generator", asset.generator, o);
// }

// if (!asset.copyright.empty()) {
//     SerializeStringProperty("copyright", asset.copyright, o);
// }

// auto version_ = asset.version_;
// if (version_.empty()) {
//     // Just in case
//     // `version` must be defined
//     version_ = "2.0";
// }

// // TODO(syoyo): Do we need to check if `version` is greater or equal to 2.0?
// SerializeStringProperty("version", version_, o);

// if (asset.extras.Keys().size()) {
//     SerializeValue("extras", asset.extras, o);
// }

// SerializeExtensionMap(asset.extensions, o);
// }

// private void SerializeGltfBufferBin(const(Buffer) buffer, detail o, std binBuffer) {
// SerializeNumberProperty("byteLength", buffer.data.size(), o);
// binBuffer = buffer.data;

// if (buffer.name.size()) SerializeStringProperty("name", buffer.name, o);

// if (buffer.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", buffer.extras, o);
// }
// }

// private void SerializeGltfBuffer(const(Buffer) buffer, detail o) {
// SerializeNumberProperty("byteLength", buffer.data.size(), o);
// SerializeGltfBufferData(buffer.data, o);

// if (buffer.name.size()) SerializeStringProperty("name", buffer.name, o);

// if (buffer.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", buffer.extras, o);
// }
// }

// private bool SerializeGltfBuffer(const(Buffer) buffer, detail o, const(std) binFilename, const(std) binUri) {
// if (!SerializeGltfBufferData(buffer.data, binFilename)) return false;
// SerializeNumberProperty("byteLength", buffer.data.size(), o);
// SerializeStringProperty("uri", binUri, o);

// if (buffer.name.size()) SerializeStringProperty("name", buffer.name, o);

// if (buffer.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", buffer.extras, o);
// }
// return true;
// }

// private void SerializeGltfBufferView(const(BufferView) bufferView, detail o) {
// SerializeNumberProperty("buffer", bufferView.buffer, o);
// SerializeNumberProperty<size_t>("byteLength", bufferView.byteLength, o);

// // byteStride is optional, minimum allowed is 4
// if (bufferView.byteStride >= 4) {
//     SerializeNumberProperty<size_t>("byteStride", bufferView.byteStride, o);
// }
// // byteOffset is optional, default is 0
// if (bufferView.byteOffset > 0) {
//     SerializeNumberProperty<size_t>("byteOffset", bufferView.byteOffset, o);
// }
// // Target is optional, check if it contains a valid value
// if (bufferView.target == TINYGLTF_TARGET_ARRAY_BUFFER ||
//     bufferView.target == TINYGLTF_TARGET_ELEMENT_ARRAY_BUFFER) {
//     SerializeNumberProperty("target", bufferView.target, o);
// }
// if (bufferView.name.size()) {
//     SerializeStringProperty("name", bufferView.name, o);
// }

// if (bufferView.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", bufferView.extras, o);
// }
// }

// private void SerializeGltfImage(const(Image) image, const(std) uri, detail o) {
// // From 2.7.0, we look for `uri` parameter, not `Image.uri`
// // if uri is empty, the mimeType and bufferview should be set
// if (uri.empty()) {
//     SerializeStringProperty("mimeType", image.mimeType, o);
//     SerializeNumberProperty<int>("bufferView", image.bufferView, o);
// } else {
//     SerializeStringProperty("uri", uri, o);
// }

// if (image.name.size()) {
//     SerializeStringProperty("name", image.name, o);
// }

// if (image.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", image.extras, o);
// }

// SerializeExtensionMap(image.extensions, o);
// }

// private void SerializeGltfTextureInfo(const(TextureInfo) texinfo, detail o) {
// SerializeNumberProperty("index", texinfo.index, o);

// if (texinfo.texCoord != 0) {
//     SerializeNumberProperty("texCoord", texinfo.texCoord, o);
// }

// if (texinfo.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", texinfo.extras, o);
// }

// SerializeExtensionMap(texinfo.extensions, o);
// }

// private void SerializeGltfNormalTextureInfo(const(NormalTextureInfo) texinfo, detail o) {
// SerializeNumberProperty("index", texinfo.index, o);

// if (texinfo.texCoord != 0) {
//     SerializeNumberProperty("texCoord", texinfo.texCoord, o);
// }

// if (!TINYGLTF_DOUBLE_EQUAL(texinfo.scale, 1.0)) {
//     SerializeNumberProperty("scale", texinfo.scale, o);
// }

// if (texinfo.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", texinfo.extras, o);
// }

// SerializeExtensionMap(texinfo.extensions, o);
// }

// private void SerializeGltfOcclusionTextureInfo(const(OcclusionTextureInfo) texinfo, detail o) {
// SerializeNumberProperty("index", texinfo.index, o);

// if (texinfo.texCoord != 0) {
//     SerializeNumberProperty("texCoord", texinfo.texCoord, o);
// }

// if (!TINYGLTF_DOUBLE_EQUAL(texinfo.strength, 1.0)) {
//     SerializeNumberProperty("strength", texinfo.strength, o);
// }

// if (texinfo.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", texinfo.extras, o);
// }

// SerializeExtensionMap(texinfo.extensions, o);
// }

// static void SerializeGltfPbrMetallicRoughness(const(PbrMetallicRoughness) pbr,
//                                             detail o) {
// std::vector<double> default_baseColorFactor = {1.0, 1.0, 1.0, 1.0};
// if (!Equals(pbr.baseColorFactor, default_baseColorFactor)) {
//     SerializeNumberArrayProperty<double>("baseColorFactor", pbr.baseColorFactor,
//                                         o);
// }

// if (!TINYGLTF_DOUBLE_EQUAL(pbr.metallicFactor, 1.0)) {
//     SerializeNumberProperty("metallicFactor", pbr.metallicFactor, o);
// }

// if (!TINYGLTF_DOUBLE_EQUAL(pbr.roughnessFactor, 1.0)) {
//     SerializeNumberProperty("roughnessFactor", pbr.roughnessFactor, o);
// }

// if (pbr.baseColorTexture.index > -1) {
//     detail::json texinfo;
//     SerializeGltfTextureInfo(pbr.baseColorTexture, texinfo);
//     detail::JsonAddMember(o, "baseColorTexture", std::move(texinfo));
// }

// if (pbr.metallicRoughnessTexture.index > -1) {
//     detail::json texinfo;
//     SerializeGltfTextureInfo(pbr.metallicRoughnessTexture, texinfo);
//     detail::JsonAddMember(o, "metallicRoughnessTexture", std::move(texinfo));
// }

// SerializeExtensionMap(pbr.extensions, o);

// if (pbr.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", pbr.extras, o);
// }
// }

// private void SerializeGltfMaterial(const(Material) material, detail o) {
// if (material.name.size()) {
//     SerializeStringProperty("name", material.name, o);
// }

// // QUESTION(syoyo): Write material parameters regardless of its default value?

// if (!TINYGLTF_DOUBLE_EQUAL(material.alphaCutoff, 0.5)) {
//     SerializeNumberProperty("alphaCutoff", material.alphaCutoff, o);
// }

// if (material.alphaMode.compare("OPAQUE") != 0) {
//     SerializeStringProperty("alphaMode", material.alphaMode, o);
// }

// if (material.doubleSided != false)
//     detail::JsonAddMember(o, "doubleSided", detail::json(material.doubleSided));

// if (material.normalTexture.index > -1) {
//     detail::json texinfo;
//     SerializeGltfNormalTextureInfo(material.normalTexture, texinfo);
//     detail::JsonAddMember(o, "normalTexture", std::move(texinfo));
// }

// if (material.occlusionTexture.index > -1) {
//     detail::json texinfo;
//     SerializeGltfOcclusionTextureInfo(material.occlusionTexture, texinfo);
//     detail::JsonAddMember(o, "occlusionTexture", std::move(texinfo));
// }

// if (material.emissiveTexture.index > -1) {
//     detail::json texinfo;
//     SerializeGltfTextureInfo(material.emissiveTexture, texinfo);
//     detail::JsonAddMember(o, "emissiveTexture", std::move(texinfo));
// }

// std::vector<double> default_emissiveFactor = {0.0, 0.0, 0.0};
// if (!Equals(material.emissiveFactor, default_emissiveFactor)) {
//     SerializeNumberArrayProperty<double>("emissiveFactor",
//                                         material.emissiveFactor, o);
// }

// {
//     detail::json pbrMetallicRoughness;
//     SerializeGltfPbrMetallicRoughness(material.pbrMetallicRoughness,
//                                     pbrMetallicRoughness);
//     // Issue 204
//     // Do not serialize `pbrMetallicRoughness` if pbrMetallicRoughness has all
//     // default values(json is null). Otherwise it will serialize to
//     // `pbrMetallicRoughness : null`, which cannot be read by other glTF
//     // importers (and validators).
//     //
//     if (!detail::JsonIsNull(pbrMetallicRoughness)) {
//     detail::JsonAddMember(o, "pbrMetallicRoughness", std::move(pbrMetallicRoughness));
//     }
// }

// version (none) {  // legacy way. just for the record.
// if (material.values.size()) {
//     detail::json pbrMetallicRoughness;
//     SerializeParameterMap(material.values, pbrMetallicRoughness);
//     detail::JsonAddMember(o, "pbrMetallicRoughness", std::move(pbrMetallicRoughness));
// }

// SerializeParameterMap(material.additionalValues, o);
// } else {

// }

// SerializeExtensionMap(material.extensions, o);

// if (material.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", material.extras, o);
// }
// }

// private void SerializeGltfMesh(const(Mesh) mesh, detail o) {
// detail::json primitives;
// detail::JsonReserveArray(primitives, mesh.primitives.size());
// for (uint i = 0; i < mesh.primitives.size(); ++i) {
//     detail::json primitive;
//     const(Primitive) gltfPrimitive = mesh.primitives[i];  // don't make a copy
//     {
//     detail::json attributes;
//     for (auto attrIt = gltfPrimitive.attributes.begin();
//         attrIt != gltfPrimitive.attributes.end(); ++attrIt) {
//         SerializeNumberProperty<int>(attrIt.first, attrIt.second, attributes);
//     }

//     detail::JsonAddMember(primitive, "attributes", std::move(attributes));
//     }

//     // Indices is optional
//     if (gltfPrimitive.indices > -1) {
//     SerializeNumberProperty<int>("indices", gltfPrimitive.indices, primitive);
//     }
//     // Material is optional
//     if (gltfPrimitive.material > -1) {
//     SerializeNumberProperty<int>("material", gltfPrimitive.material,
//                                 primitive);
//     }
//     SerializeNumberProperty<int>("mode", gltfPrimitive.mode, primitive);

//     // Morph targets
//     if (gltfPrimitive.targets.size()) {
//     detail::json targets;
//     detail::JsonReserveArray(targets, gltfPrimitive.targets.size());
//     for (uint k = 0; k < gltfPrimitive.targets.size(); ++k) {
//         detail::json targetAttributes;
//         std::map<std::string, int> targetData = gltfPrimitive.targets[k];
//         for (std string = void, attrIt = targetData.begin();
//             attrIt != targetData.end(); ++attrIt) {
//         SerializeNumberProperty<int>(attrIt.first, attrIt.second,
//                                     targetAttributes);
//         }
//         detail::JsonPushBack(targets, std::move(targetAttributes));
//     }
//     detail::JsonAddMember(primitive, "targets", std::move(targets));
//     }

//     SerializeExtensionMap(gltfPrimitive.extensions, primitive);

//     if (gltfPrimitive.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", gltfPrimitive.extras, primitive);
//     }

//     detail::JsonPushBack(primitives, std::move(primitive));
// }

// detail::JsonAddMember(o, "primitives", std::move(primitives));

// if (mesh.weights.size()) {
//     SerializeNumberArrayProperty<double>("weights", mesh.weights, o);
// }

// if (mesh.name.size()) {
//     SerializeStringProperty("name", mesh.name, o);
// }

// SerializeExtensionMap(mesh.extensions, o);
// if (mesh.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", mesh.extras, o);
// }
// }

// private void SerializeSpotLight(const(SpotLight) spot, detail o) {
// SerializeNumberProperty("innerConeAngle", spot.innerConeAngle, o);
// SerializeNumberProperty("outerConeAngle", spot.outerConeAngle, o);
// SerializeExtensionMap(spot.extensions, o);
// if (spot.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", spot.extras, o);
// }
// }

// private void SerializeGltfLight(const(Light) light, detail o) {
// if (!light.name.empty()) SerializeStringProperty("name", light.name, o);
// SerializeNumberProperty("intensity", light.intensity, o);
// if (light.range > 0.0) {
//     SerializeNumberProperty("range", light.range, o);
// }
// SerializeNumberArrayProperty("color", light.color, o);
// SerializeStringProperty("type", light.type, o);
// if (light.type == "spot") {
//     detail::json spot;
//     SerializeSpotLight(light.spot, spot);
//     detail::JsonAddMember(o, "spot", std::move(spot));
// }
// SerializeExtensionMap(light.extensions, o);
// if (light.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", light.extras, o);
// }
// }

// private void SerializeGltfNode(const(Node) node, detail o) {
// if (node.translation.size() > 0) {
//     SerializeNumberArrayProperty<double>("translation", node.translation, o);
// }
// if (node.rotation.size() > 0) {
//     SerializeNumberArrayProperty<double>("rotation", node.rotation, o);
// }
// if (node.scale.size() > 0) {
//     SerializeNumberArrayProperty<double>("scale", node.scale, o);
// }
// if (node.matrix.size() > 0) {
//     SerializeNumberArrayProperty<double>("matrix", node.matrix, o);
// }
// if (node.mesh != -1) {
//     SerializeNumberProperty<int>("mesh", node.mesh, o);
// }

// if (node.skin != -1) {
//     SerializeNumberProperty<int>("skin", node.skin, o);
// }

// if (node.camera != -1) {
//     SerializeNumberProperty<int>("camera", node.camera, o);
// }

// if (node.weights.size() > 0) {
//     SerializeNumberArrayProperty<double>("weights", node.weights, o);
// }

// if (node.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", node.extras, o);
// }

// SerializeExtensionMap(node.extensions, o);
// if (!node.name.empty()) SerializeStringProperty("name", node.name, o);
// SerializeNumberArrayProperty<int>("children", node.children, o);
// }

// private void SerializeGltfSampler(const(Sampler) sampler, detail o) {
// if (!sampler.name.empty()) {
//     SerializeStringProperty("name", sampler.name, o);
// }
// if (sampler.magFilter != -1) {
//     SerializeNumberProperty("magFilter", sampler.magFilter, o);
// }
// if (sampler.minFilter != -1) {
//     SerializeNumberProperty("minFilter", sampler.minFilter, o);
// }
// // SerializeNumberProperty("wrapR", sampler.wrapR, o);
// SerializeNumberProperty("wrapS", sampler.wrapS, o);
// SerializeNumberProperty("wrapT", sampler.wrapT, o);

// if (sampler.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", sampler.extras, o);
// }
// }

// private void SerializeGltfOrthographicCamera(const(OrthographicCamera) camera, detail o) {
// SerializeNumberProperty("zfar", camera.zfar, o);
// SerializeNumberProperty("znear", camera.znear, o);
// SerializeNumberProperty("xmag", camera.xmag, o);
// SerializeNumberProperty("ymag", camera.ymag, o);

// if (camera.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", camera.extras, o);
// }
// }

// private void SerializeGltfPerspectiveCamera(const(PerspectiveCamera) camera, detail o) {
// SerializeNumberProperty("zfar", camera.zfar, o);
// SerializeNumberProperty("znear", camera.znear, o);
// if (camera.aspectRatio > 0) {
//     SerializeNumberProperty("aspectRatio", camera.aspectRatio, o);
// }

// if (camera.yfov > 0) {
//     SerializeNumberProperty("yfov", camera.yfov, o);
// }

// if (camera.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", camera.extras, o);
// }
// }

// private void SerializeGltfCamera(const(Camera) camera, detail o) {
// SerializeStringProperty("type", camera.type, o);
// if (!camera.name.empty()) {
//     SerializeStringProperty("name", camera.name, o);
// }

// if (camera.type.compare("orthographic") == 0) {
//     detail::json orthographic;
//     SerializeGltfOrthographicCamera(camera.orthographic, orthographic);
//     detail::JsonAddMember(o, "orthographic", std::move(orthographic));
// } else if (camera.type.compare("perspective") == 0) {
//     detail::json perspective;
//     SerializeGltfPerspectiveCamera(camera.perspective, perspective);
//     detail::JsonAddMember(o, "perspective", std::move(perspective));
// } else {
//     // ???
// }

// if (camera.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", camera.extras, o);
// }
// SerializeExtensionMap(camera.extensions, o);
// }

// private void SerializeGltfScene(const(Scene) scene, detail o) {
// SerializeNumberArrayProperty<int>("nodes", scene.nodes, o);

// if (scene.name.size()) {
//     SerializeStringProperty("name", scene.name, o);
// }
// if (scene.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", scene.extras, o);
// }
// SerializeExtensionMap(scene.extensions, o);
// }

// private void SerializeGltfSkin(const(Skin) skin, detail o) {
// // required
// SerializeNumberArrayProperty<int>("joints", skin.joints, o);

// if (skin.inverseBindMatrices >= 0) {
//     SerializeNumberProperty("inverseBindMatrices", skin.inverseBindMatrices, o);
// }

// if (skin.skeleton >= 0) {
//     SerializeNumberProperty("skeleton", skin.skeleton, o);
// }

// if (skin.name.size()) {
//     SerializeStringProperty("name", skin.name, o);
// }
// }

// private void SerializeGltfTexture(const(Texture) texture, detail o) {
// if (texture.sampler > -1) {
//     SerializeNumberProperty("sampler", texture.sampler, o);
// }
// if (texture.source > -1) {
//     SerializeNumberProperty("source", texture.source, o);
// }
// if (texture.name.size()) {
//     SerializeStringProperty("name", texture.name, o);
// }
// if (texture.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", texture.extras, o);
// }
// SerializeExtensionMap(texture.extensions, o);
// }

// ///
// /// Serialize all properties except buffers and images.
// ///
// private void SerializeGltfModel(const(Model)* model, detail o) {
// // ACCESSORS
// if (model.accessors.size()) {
//     detail::json accessors;
//     detail::JsonReserveArray(accessors, model.accessors.size());
//     for (uint i = 0; i < model.accessors.size(); ++i) {
//     detail::json accessor;
//     SerializeGltfAccessor(model.accessors[i], accessor);
//     detail::JsonPushBack(accessors, std::move(accessor));
//     }
//     detail::JsonAddMember(o, "accessors", std::move(accessors));
// }

// // ANIMATIONS
// if (model.animations.size()) {
//     detail::json animations;
//     detail::JsonReserveArray(animations, model.animations.size());
//     for (uint i = 0; i < model.animations.size(); ++i) {
//     if (model.animations[i].channels.size()) {
//         detail::json animation;
//         SerializeGltfAnimation(model.animations[i], animation);
//         detail::JsonPushBack(animations, std::move(animation));
//     }
//     }

//     detail::JsonAddMember(o, "animations", std::move(animations));
// }

// // ASSET
// detail::json asset;
// SerializeGltfAsset(model.asset, asset);
// detail::JsonAddMember(o, "asset", std::move(asset));

// // BUFFERVIEWS
// if (model.bufferViews.size()) {
//     detail::json bufferViews;
//     detail::JsonReserveArray(bufferViews, model.bufferViews.size());
//     for (uint i = 0; i < model.bufferViews.size(); ++i) {
//     detail::json bufferView;
//     SerializeGltfBufferView(model.bufferViews[i], bufferView);
//     detail::JsonPushBack(bufferViews, std::move(bufferView));
//     }
//     detail::JsonAddMember(o, "bufferViews", std::move(bufferViews));
// }

// // Extensions required
// if (model.extensionsRequired.size()) {
//     SerializeStringArrayProperty("extensionsRequired",
//                                 model.extensionsRequired, o);
// }

// // MATERIALS
// if (model.materials.size()) {
//     detail::json materials;
//     detail::JsonReserveArray(materials, model.materials.size());
//     for (uint i = 0; i < model.materials.size(); ++i) {
//     detail::json material;
//     SerializeGltfMaterial(model.materials[i], material);

//     if (detail::JsonIsNull(material)) {
//         // Issue 294.
//         // `material` does not have any required parameters
//         // so the result may be null(unmodified) when all material parameters
//         // have default value.
//         //
//         // null is not allowed thus we create an empty JSON object.
//         detail::JsonSetObject(material);
//     }
//     detail::JsonPushBack(materials, std::move(material));
//     }
//     detail::JsonAddMember(o, "materials", std::move(materials));
// }

// // MESHES
// if (model.meshes.size()) {
//     detail::json meshes;
//     detail::JsonReserveArray(&meshes, model.meshes.size());
//     for (uint i = 0; i < model.meshes.size(); ++i) {
//     detail::json mesh;
//     SerializeGltfMesh(model.meshes[i], mesh);
//     detail::JsonPushBack(&meshes, std::move(mesh));
//     }
//     detail::JsonAddMember(o, "meshes", std::move(&meshes));
// }

// // NODES
// if (model.nodes.size()) {
//     detail::json nodes;
//     detail::JsonReserveArray(nodes, model.nodes.size());
//     for (uint i = 0; i < model.nodes.size(); ++i) {
//     detail::json node;
//     SerializeGltfNode(model.nodes[i], node);
//     detail::JsonPushBack(nodes, std::move(node));
//     }
//     detail::JsonAddMember(o, "nodes", std::move(nodes));
// }

// // SCENE
// if (model.defaultScene > -1) {
//     SerializeNumberProperty<int>("scene", model.defaultScene, o);
// }

// // SCENES
// if (model.scenes.size()) {
//     detail::json scenes;
//     detail::JsonReserveArray(scenes, model.scenes.size());
//     for (uint i = 0; i < model.scenes.size(); ++i) {
//     detail::json currentScene;
//     SerializeGltfScene(model.scenes[i], currentScene);
//     detail::JsonPushBack(scenes, std::move(currentScene));
//     }
//     detail::JsonAddMember(o, "scenes", std::move(scenes));
// }

// // SKINS
// if (model.skins.size()) {
//     detail::json skins;
//     detail::JsonReserveArray(skins, model.skins.size());
//     for (uint i = 0; i < model.skins.size(); ++i) {
//     detail::json skin;
//     SerializeGltfSkin(model.skins[i], skin);
//     detail::JsonPushBack(skins, std::move(skin));
//     }
//     detail::JsonAddMember(o, "skins", std::move(skins));
// }

// // TEXTURES
// if (model.textures.size()) {
//     detail::json textures;
//     detail::JsonReserveArray(textures, model.textures.size());
//     for (uint i = 0; i < model.textures.size(); ++i) {
//     detail::json texture;
//     SerializeGltfTexture(model.textures[i], texture);
//     detail::JsonPushBack(textures, std::move(texture));
//     }
//     detail::JsonAddMember(o, "textures", std::move(textures));
// }

// // SAMPLERS
// if (model.samplers.size()) {
//     detail::json samplers;
//     detail::JsonReserveArray(samplers, model.samplers.size());
//     for (uint i = 0; i < model.samplers.size(); ++i) {
//     detail::json sampler;
//     SerializeGltfSampler(model.samplers[i], sampler);
//     detail::JsonPushBack(samplers, std::move(sampler));
//     }
//     detail::JsonAddMember(o, "samplers", std::move(samplers));
// }

// // CAMERAS
// if (model.cameras.size()) {
//     detail::json cameras;
//     detail::JsonReserveArray(cameras, model.cameras.size());
//     for (uint i = 0; i < model.cameras.size(); ++i) {
//     detail::json camera;
//     SerializeGltfCamera(model.cameras[i], camera);
//     detail::JsonPushBack(cameras, std::move(camera));
//     }
//     detail::JsonAddMember(o, "cameras", std::move(cameras));
// }

// // EXTENSIONS
// SerializeExtensionMap(model.extensions, o);

// auto extensionsUsed = model.extensionsUsed;

// // LIGHTS as KHR_lights_punctual
// if (model.lights.size()) {
//     detail::json lights;
//     detail::JsonReserveArray(lights, model.lights.size());
//     for (uint i = 0; i < model.lights.size(); ++i) {
//     detail::json light;
//     SerializeGltfLight(model.lights[i], light);
//     detail::JsonPushBack(lights, std::move(light));
//     }
//     detail::json khr_lights_cmn;
//     detail::JsonAddMember(khr_lights_cmn, "lights", std::move(lights));
//     detail::json ext_j;

//     {
//     detail::json_const_iterator it;
//     if (detail::FindMember(o, "extensions", it)) {
//         detail::JsonAssign(ext_j, detail::GetValue(it));
//     }
//     }

//     detail::JsonAddMember(ext_j, "KHR_lights_punctual", std::move(khr_lights_cmn));

//     detail::JsonAddMember(o, "extensions", std::move(ext_j));

//     // Also add "KHR_lights_punctual" to `extensionsUsed`
//     {
//     auto has_khr_lights_punctual find_if(extensionsUsed begin(), extensionsUsed end(),  function(const(std) s)) {
//                         return (s.compare("KHR_lights_punctual") == 0);
//                     }){}

//     if (has_khr_lights_punctual == extensionsUsed.end()) {
//         extensionsUsed.push_back("KHR_lights_punctual");
//     }
//     }
// }

// // Extensions used
// if (extensionsUsed.size()) {
//     SerializeStringArrayProperty("extensionsUsed", extensionsUsed, o);
// }

// // EXTRAS
// if (model.extras.Type() != NULL_TYPE) {
//     SerializeValue("extras", model.extras, o);
// }
// }

// private bool WriteGltfStream(std stream, const(std) content) {
// stream << content << std::endl;
// return true;
// }

// private bool WriteGltfFile(const(std) output, const(std) content) {
// version (Windows) {
// version (_MSC_VER) {
// std::ofstream gltfFile(UTF8ToWchar(output).c_str());
// } else version (__GLIBCXX__) {
// int file_descriptor = _wopen(UTF8ToWchar(output).c_str(),
//                             _O_CREAT | _O_WRONLY | _O_TRUNC | _O_BINARY);
// __gnu_cxx::stdio_filebuf<char_> wfile_buf(
//     file_descriptor, std::ios_base::out_ | std::ios_base::binary);
// std::ostream gltfFile(&wfile_buf);
// if (!wfile_buf.is_open()) return false;
// } else {
// std::ofstream gltfFile(output.c_str());
// if (!gltfFile.is_open()) return false;
// }
// } else {
// std::ofstream gltfFile(output.c_str());
// if (!gltfFile.is_open()) return false;
// }
// return WriteGltfStream(gltfFile, content);
// }

// private bool WriteBinaryGltfStream(std stream, const(std) content, const(std) binBuffer) {
// const(std) header = "glTF";
// const(int) version_ = 2;

// const(uint) content_size = uint32_t(content.size());
// const(uint) binBuffer_size = uint32_t(binBuffer.size());
// // determine number of padding bytes required to ensure 4 byte alignment
// const(uint) content_padding_size = content_size % 4 == 0 ? 0 : 4 - content_size % 4;
// const(uint) bin_padding_size = binBuffer_size % 4 == 0 ? 0 : 4 - binBuffer_size % 4;

// // 12 bytes for header, JSON content length, 8 bytes for JSON chunk info.
// // Chunk data must be located at 4-byte boundary, which may require padding
// const(uint) length = 12 + 8 + content_size + content_padding_size +
//     (binBuffer_size ? (8 + binBuffer_size + bin_padding_size) : 0);

// stream.write(header.c_str(), std::streamsize(header.size()));
// stream.write(reinterpret_cast<const char_ *>(&version_), version_.sizeof);
// stream.write(reinterpret_cast<const char_ *>(&length), length.sizeof);

// // JSON chunk info, then JSON data
// const(uint) model_length = uint32_t(content.size()) + content_padding_size;
// const(uint) model_format = 0x4E4F534A;
// stream.write(reinterpret_cast<const char_ *>(&model_length),
//             model_length.sizeof);
// stream.write(reinterpret_cast<const char_ *>(&model_format),
//             model_format.sizeof);
// stream.write(content.c_str(), std::streamsize(content.size()));

// // Chunk must be multiplies of 4, so pad with spaces
// if (content_padding_size > 0) {
//     const(std) padding = string(size_t(content_padding_size), ' ');
//     stream.write(padding.c_str(), std::streamsize(padding.size()));
// }
// if (binBuffer.size() > 0) {
//     // BIN chunk info, then BIN data
//     const(uint) bin_length = uint32_t(binBuffer.size()) + bin_padding_size;
//     const(uint) bin_format = 0x004e4942;
//     stream.write(reinterpret_cast<const char_ *>(&bin_length),
//                 bin_length.sizeof);
//     stream.write(reinterpret_cast<const char_ *>(&bin_format),
//                 bin_format.sizeof);
//     stream.write(reinterpret_cast<const char_ *>(binBuffer.data()),
//                 std::streamsize(binBuffer.size()));
//     // Chunksize must be multiplies of 4, so pad with zeroes
//     if (bin_padding_size > 0) {
//     const(std) padding = vector<unsigned char_>(size_t, 0);
//     stream.write(reinterpret_cast<const char_ *>(padding.data()),
//                 std::streamsize(padding.size()));
//     }
// }

// // TODO: Check error on stream.write
// return true;
// }

// private bool WriteBinaryGltfFile(const(std) output, const(std) content, const(std) binBuffer) {
// version (Windows) {
// version (_MSC_VER) {
// std::ofstream gltfFile(UTF8ToWchar(output).c_str(), std::ios::binary);
// } else version (__GLIBCXX__) {
// int file_descriptor = _wopen(UTF8ToWchar(output).c_str(),
//                             _O_CREAT | _O_WRONLY | _O_TRUNC | _O_BINARY);
// __gnu_cxx::stdio_filebuf<char_> wfile_buf(
//     file_descriptor, std::ios_base::out_ | std::ios_base::binary);
// std::ostream gltfFile(&wfile_buf);
// } else {
// std::ofstream gltfFile(output.c_str(), std::ios::binary);
// }
// } else {
// std::ofstream gltfFile(output.c_str(), std::ios::binary);
// }
// return WriteBinaryGltfStream(gltfFile, content, binBuffer);
// }

// bool WriteGltfSceneToStream(const(Model)* model, std stream, bool prettyPrint); bool writeBinary = {
// detail::JsonDocument output;

// /// Serialize all properties except buffers and images.
// SerializeGltfModel(model, output);

// // BUFFERS
// std::vector<unsigned char_> binBuffer;
// if (model.buffers.size()) {
//     detail::json buffers;
//     detail::JsonReserveArray(buffers, model.buffers.size());
//     for (uint i = 0; i < model.buffers.size(); ++i) {
//     detail::json buffer;
//     if (writeBinary && i == 0 && model.buffers[i].uri.empty()) {
//         SerializeGltfBufferBin(model.buffers[i], buffer, binBuffer);
//     } else {
//         SerializeGltfBuffer(model.buffers[i], buffer);
//     }
//     detail::JsonPushBack(buffers, std::move(buffer));
//     }
//     detail::JsonAddMember(output, "buffers", std::move(buffers));
// }

// // IMAGES
// if (model.images.size()) {
//     detail::json images;
//     detail::JsonReserveArray(images, model.images.size());
//     for (uint i = 0; i < model.images.size(); ++i) {
//     detail::json image;

//     std::string dummystring = "";
//     // UpdateImageObject need baseDir but only uses it if embeddedImages is
//     // enabled, since we won't write separate images when writing to a stream
//     // we
//     std::string uri;
//     if (!UpdateImageObject(model.images[i], dummystring, int(i), true,
//                             &uri_cb, &this_.WriteImageData,
//                             this_.write_image_user_data_, &uri)) {
//         return false;
//     }
//     SerializeGltfImage(model.images[i], uri, image);
//     detail::JsonPushBack(images, std::move(image));
//     }
//     detail::JsonAddMember(output, "images", std::move(images));
// }

// if (writeBinary) {
//     return WriteBinaryGltfStream(stream, detail::JsonToString(output), binBuffer);
// } else {
//     return WriteGltfStream(stream, detail::JsonToString(output, prettyPrint ? 2 : -1));
// }
// }

// bool WriteGltfSceneToFile(const(Model)* model, const(std) filename, bool embedImages); bool embedBuffers = false, prettyPrint = true, writeBinary = {
// detail::JsonDocument output;
// std::string defaultBinFilename = GetBaseFilename(filename);
// std::string defaultBinFileExt = ".bin";
// std::string::size_type pos =
//     defaultBinFilename.rfind('.', defaultBinFilename.length());

// if (pos != std::string::npos) {
//     defaultBinFilename = defaultBinFilename.substr(0, pos);
// }
// std::string baseDir = GetBaseDir(filename);
// if (baseDir.empty()) {
//     baseDir = "./";
// }
// /// Serialize all properties except buffers and images.
// SerializeGltfModel(model, output);

// // BUFFERS
// std::vector<std::string> usedFilenames;
// std::vector<unsigned char_> binBuffer;
// if (model.buffers.size()) {
//     detail::json buffers;
//     detail::JsonReserveArray(buffers, model.buffers.size());
//     for (uint i = 0; i < model.buffers.size(); ++i) {
//     detail::json buffer;
//     if (writeBinary && i == 0 && model.buffers[i].uri.empty()) {
//         SerializeGltfBufferBin(model.buffers[i], buffer, binBuffer);
//     } else if (embedBuffers) {
//         SerializeGltfBuffer(model.buffers[i], buffer);
//     } else {
//         std::string binSavePath;
//         std::string binFilename;
//         std::string binUri;
//         if (!model.buffers[i].uri.empty() &&
//             !IsDataURI(model.buffers[i].uri)) {
//         binUri = model.buffers[i].uri;
//         if (!uri_cb.decode(binUri, &binFilename, uri_cb.user_data)) {
//             return false;
//         }
//         } else {
//         binFilename = defaultBinFilename + defaultBinFileExt;
//         bool inUse = true;
//         int numUsed = 0;
//         while (inUse) {
//             inUse = false;
//             for (const(std) continue;
//             inUse = true;
//             binFilename = defaultBinFilename + std::to_string(numUsed++) +
//                             defaultBinFileExt;
//             break;
//             }
//         }

//         if (uri_cb.encode) {
//             if (!uri_cb.encode(binFilename, "buffer", &binUri,
//                             uri_cb.user_data)) {
//             return false;
//             }
//         } else {
//             binUri = binFilename;
//         }
//         }
//         usedFilenames.push_back(binFilename);
//         binSavePath = JoinPath(baseDir, binFilename);
//         if (!SerializeGltfBuffer(model.buffers[i], buffer, binSavePath,
//                                 binUri)) {
//         return false;
//         }
//     }
//     detail::JsonPushBack(buffers, std::move(buffer));
//     }
//     detail::JsonAddMember(output, "buffers", std::move(buffers));
// }

// // IMAGES
// if (model.images.size()) {
//     detail::json images;
//     detail::JsonReserveArray(images, model.images.size());
//     for (unsigned int i = 0; i < model.images.size(); ++i) {
//     detail::json image;

//     std::string uri;
//     if (!UpdateImageObject(model.images[i], baseDir, int(i), embedImages,
//                             &uri_cb, &this_.WriteImageData,
//                             this_.write_image_user_data_, &uri)) {
//         return false;
//     }
//     SerializeGltfImage(model.images[i], uri, image);
//     detail::JsonPushBack(images, std::move(image));
//     }
//     detail::JsonAddMember(output, "images", std::move(images));
// }

// if (writeBinary) {
//     return WriteBinaryGltfFile(filename, detail::JsonToString(output), binBuffer);
// } else {
//     return WriteGltfFile(filename, detail::JsonToString(output, (prettyPrint ? 2 : -1)));
// }
// }
