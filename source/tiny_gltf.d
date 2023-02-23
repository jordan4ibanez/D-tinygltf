import std.stdio;
import std.string;

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

// enum TINYGLTF_DOUBLE_EPS = (1.e-12);
// enum string TINYGLTF_DOUBLE_EQUAL(string a, string b) = ` (std::fabs((b) - (a)) < TINYGLTF_DOUBLE_EPS)`;


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

alias NULL_TYPE   = Type.NULL_TYPE;
alias REAL_TYPE   = Type.REAL_TYPE;
alias INT_TYPE    = Type.INT_TYPE;
alias BOOL_TYPE   = Type.BOOL_TYPE;
alias STRING_TYPE = Type.STRING_TYPE;
alias ARRAY_TYPE  = Type.ARRAY_TYPE;
alias BINARY_TYPE = Type.BINARY_TYPE;
alias OBJECT_TYPE = Type.OBJECT_TYPE;


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
//* Translation Note: This whole thing is duck typed
class Value {

public:

    //* Translation Note: These were typedefs
    // C++ vector is dynamic array
    // Value[] array;
    // C++ map is an Associative Array
    // Value[string] object;

    // The value becomes whatever it is constructed with
    // It is a zeitgeist basically
    // The period of time in this zeitgeist is the life time of it
    // this. is not required, but I like it
    this() {
        this.type_ = NULL_TYPE;
        this.int_value_ = 0;
        this.real_value_ = 0.0;
        this.boolean_value = false;
    }
    
    this(bool b) {
        this.boolean_value_ = b;
        this.type = BOOL_TYPE;
    }

    this(int i) {
        this.int_value_ = i;
        this.real_value_ = i;
        this.type = INT_TYPE;
    }

    this(double n) {
        this.real_value_ = n;
        this.type_ = REAL_TYPE;
    }

    this(string s) {
        this.string_value_ = s;
        this.type = STRING_TYPE;
    }

    this(ubyte[] v) {
        this.binary_value_ = v;
        this.type = BINARY_TYPE;
    }
    
    this(const Value[] a) {
        this.array_value_ = a;
        this.type = ARRAY_TYPE;
    }

    this(const Value[string] o) {
        this.object_value_ = o;
        this.type = OBJECT_TYPE;
    }

    Type type(){
        return this.type_;
    }

    bool isBool() {
        return (this.type_ == BOOL_TYPE);
    }

    bool isInt() {
        return (this.type_ == INT_TYPE);
    }

    bool isNumber() {
        return (this.type_ == REAL_TYPE) || (this.type_ == INT_TYPE);
    }

    bool isReal() {
        return (this.type_ == REAL_TYPE);
    }

    bool isString() {
        return (this.type_ == STRING_TYPE);
    }

    bool isBinary() {
        return (this.type_ == BINARY_TYPE);
    }

    bool isArray() {
        return (this.type_ == ARRAY_TYPE);
    }

    bool isObject() {
        return (this.type_ == OBJECT_TYPE);
    }

    // Use this function if you want to have number value as double.
    double getNumberAsDouble() {
        if (this.type_ == INT_TYPE) {
            return cast(double)this.int_value_;
        } else {
            return this.real_value_;
        }
    }

    // Use this function if you want to have number value as int.
    // TODO(syoyo): Support int value larger than 32 bits
    int getNumberAsInt() {
        if (this.type_ == REAL_TYPE) {
            return cast(int)this.real_value_;
        } else {
            return this.int_value_;
        }
    }

    // Lookup value from an array
    Value get(int idx) const {
        static Value null_value;
        assert(this.isArray());
        assert(idx >= 0);
        return (idx < this.array_value_.length) ? array_value_[idx] : null_value;
    }

    // Lookup value from a key-value pair
    Value get(const string key) const {
        static Value null_value;
        assert(this.isArray());
        assert(this.isObject());
        return object_value_.get(key, null_value);
    }

    size_t arrayLen() {
        if (!this.isArray())
            return 0;
        return this.array_value_.length;
    }

    // Valid only for object type.
    bool has(const string key) {
        if (!this.isObject())
            return false;
        return (key in this.object_value_) != null;
    }

    // List keys
    string[] keys() const {
        // Clone in memory
        string[] tempKeys;
        foreach (k,v; this.object_value_) {
            tempKeys ~= k;
        }
        return tempKeys;
    }

    size_t size() {
        return (this.isArray() ? this.arrayLen() : keys().length);
    }

    // This exists in D automatically
    // bool operator == (tinygltf::Value &other);


    //* Translation note: This is the more D way to do this than the weird mixin in C
    mixin(TINYGLTF_VALUE_GET("bool", "boolean_value_"));
    mixin(TINYGLTF_VALUE_GET("double", "real_value_"));
    mixin(TINYGLTF_VALUE_GET("int", "int_value_"));
    mixin(TINYGLTF_VALUE_GET("string", "string_value_"));
    mixin(TINYGLTF_VALUE_GET("ubyteArray", "binary_value_", "ubyte[]"));
    mixin(TINYGLTF_VALUE_GET("Array", "array_value_", "Value[]"));
    mixin(TINYGLTF_VALUE_GET("Object", "object_value_"));

protected:

    Type type_ = NULL_TYPE;

    int int_value_ = 0;
    double real_value_ = 0.0;
    string string_value_;
    ubyte[] binary_value_;
    Value[] array_value_;
    Value[string] object_value_;
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
alias ExtensionMap = Value[string];

class AnimationChannel {
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

    this(int sampler = -1, int target_node = -1) {
        
        this.sampler = sampler;
        this.target_node = target_node;

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
    int byteStride(const BufferView bufferViewObject) const {
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

    Accessor[] accessors;
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
/// glTF Parser/Serializer context.
///
class TinyGLTF {

public:

    // Only accepts serialized gltf json for now
    this(string fileLocation) {
        


    }/*TinyGLTF() : bin_data_(nullptr), bin_size_(0), is_binary_(false) {}*/

    //* Translation note: This literally did nothing
    // ~TinyGLTF() {}

    

private:
    ///
    /// Loads glTF asset from string(memory).
    /// `length` = strlen(str);
    /// Set warning message to `warn` for example it fails to load asserts
    /// Returns false and set error string to `err` if there's an error.
    ///
    // bool LoadFromString(Model *model, string *err, string *warn,
    //                     const char_ *str, const uint length,
    //                     const ref string base_dir, uint check_sections);

    const(ubyte)* bin_data_ = null;
    size_t bin_size_ = 0;
    bool is_binary_ = false;

    bool serialize_default_values_ = false;  ///< Serialize default values?

    bool store_original_json_for_extras_and_extensions_ = false;

    bool preserve_image_channels_ = false;  /// Default false(expand channels to
                                            /// RGBA) for backward compatibility.
}
