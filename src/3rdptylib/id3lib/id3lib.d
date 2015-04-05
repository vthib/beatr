module id3lib.id3lib;

public import id3lib.globals;

extern(C):
nothrow:

struct ID3Tag;
struct ID3TagIterator;
struct ID3TagConstIterator;
struct ID3Frame;
struct ID3Field;
struct ID3FrameInfo;

/* tag wrappers */
ID3Tag*              ID3Tag_New                  ();
void                 ID3Tag_Delete               (ID3Tag *tag);
void                 ID3Tag_Clear                (ID3Tag *tag);
bool                 ID3Tag_HasChanged           (const ID3Tag *tag);
void                 ID3Tag_SetUnsync            (ID3Tag *tag, bool unsync);
void                 ID3Tag_SetExtendedHeader    (ID3Tag *tag, bool ext);
void                 ID3Tag_SetPadding           (ID3Tag *tag, bool pad);
void                 ID3Tag_AddFrame             (ID3Tag *tag, const ID3Frame *frame);
bool                 ID3Tag_AttachFrame          (ID3Tag *tag, ID3Frame *frame);
void                 ID3Tag_AddFrames            (ID3Tag *tag, const ID3Frame *frames, size_t num);
ID3Frame*            ID3Tag_RemoveFrame          (ID3Tag *tag, const ID3Frame *frame);
ID3_Err              ID3Tag_Parse                (ID3Tag *tag, ref const(ubyte) header[ID3_TAGHEADERSIZE], const ubyte *buffer);
size_t               ID3Tag_Link                 (ID3Tag *tag, const char *fileName);
size_t               ID3Tag_LinkWithFlags        (ID3Tag *tag, const char *fileName, ushort flags);
ID3_Err              ID3Tag_Update               (ID3Tag *tag);
ID3_Err              ID3Tag_UpdateByTagType      (ID3Tag *tag, ushort type);
ID3_Err              ID3Tag_Strip                (ID3Tag *tag, ushort ulTagFlags);
ID3Frame*            ID3Tag_FindFrameWithID      (const ID3Tag *tag, ID3_FrameID id);
ID3Frame*            ID3Tag_FindFrameWithINT     (const ID3Tag *tag, ID3_FrameID id, ID3_FieldID fld, uint data);
ID3Frame*            ID3Tag_FindFrameWithASCII   (const ID3Tag *tag, ID3_FrameID id, ID3_FieldID fld, const char *data);
ID3Frame*            ID3Tag_FindFrameWithUNICODE (const ID3Tag *tag, ID3_FrameID id, ID3_FieldID fld, const wchar *data);
size_t               ID3Tag_NumFrames            (const ID3Tag *tag);
bool                 ID3Tag_HasTagType           (const ID3Tag *tag, ID3_TagType);
ID3TagIterator*      ID3Tag_CreateIterator       (ID3Tag *tag);
ID3TagConstIterator* ID3Tag_CreateConstIterator  (const ID3Tag *tag);

void                 ID3TagIterator_Delete       (ID3TagIterator*);
ID3Frame*            ID3TagIterator_GetNext      (ID3TagIterator*);
void                 ID3TagConstIterator_Delete  (ID3TagConstIterator*);
const(ID3Frame)*      ID3TagConstIterator_GetNext (ID3TagConstIterator*);

/* frame wrappers */
ID3Frame*            ID3Frame_New                ();
ID3Frame*            ID3Frame_NewID              (ID3_FrameID id);
void                 ID3Frame_Delete             (ID3Frame *frame);
void                 ID3Frame_Clear              (ID3Frame *frame);
void                 ID3Frame_SetID              (ID3Frame *frame, ID3_FrameID id);
ID3_FrameID          ID3Frame_GetID              (const ID3Frame *frame);
ID3Field*            ID3Frame_GetField           (const ID3Frame *frame, ID3_FieldID name);
void                 ID3Frame_SetCompression     (ID3Frame *frame, bool comp);
bool                 ID3Frame_GetCompression     (const ID3Frame *frame);

/* field wrappers */
void                 ID3Field_Clear              (ID3Field *field);
size_t               ID3Field_Size               (const ID3Field *field);
size_t               ID3Field_GetNumTextItems    (const ID3Field *field);
void                 ID3Field_SetINT             (ID3Field *field, uint data);
uint                 ID3Field_GetINT             (const ID3Field *field);
void                 ID3Field_SetUNICODE         (ID3Field *field, const wchar *str);
size_t               ID3Field_GetUNICODE         (const ID3Field *field, wchar *buffer, size_t maxChars);
size_t               ID3Field_GetUNICODEItem     (const ID3Field *field, wchar *buffer, size_t maxChars, size_t itemNum);
void                 ID3Field_AddUNICODE         (ID3Field *field, const wchar *str);
void                 ID3Field_SetASCII           (ID3Field *field, const char *str);
size_t               ID3Field_GetASCII           (const ID3Field *field, char *buffer, size_t maxChars);
size_t               ID3Field_GetASCIIItem       (const ID3Field *field, char *buffer, size_t maxChars, size_t itemNum);
void                 ID3Field_AddASCII           (ID3Field *field, const char *str);
void                 ID3Field_SetBINARY          (ID3Field *field, const ubyte *data, size_t size);
void                 ID3Field_GetBINARY          (const ID3Field *field, ubyte *buffer, size_t buffLength);
void                 ID3Field_FromFile           (ID3Field *field, const char *fileName);
void                 ID3Field_ToFile             (const ID3Field *field, const char *fileName);
bool                 ID3Field_SetEncoding        (ID3Field *field, ID3_TextEnc enc);
ID3_TextEnc          ID3Field_GetEncoding        (const ID3Field *field);
bool                 ID3Field_IsEncodable        (const ID3Field *field);

/* field-info wrappers */
char*                ID3FrameInfo_ShortName      (ID3_FrameID frameid);
char*                ID3FrameInfo_LongName       (ID3_FrameID frameid);
const(char)*         ID3FrameInfo_Description    (ID3_FrameID frameid);
int                  ID3FrameInfo_MaxFrameID     ();
int                  ID3FrameInfo_NumFields      (ID3_FrameID frameid);
ID3_FieldType        ID3FrameInfo_FieldType      (ID3_FrameID frameid, int fieldnum);
size_t               ID3FrameInfo_FieldSize      (ID3_FrameID frameid, int fieldnum);
ushort               ID3FrameInfo_FieldFlags     (ID3_FrameID frameid, int fieldnum);

/* Deprecated */
void                 ID3Tag_SetCompression       (ID3Tag *tag, bool comp);



