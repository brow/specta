#import "SpectaUtility.h"
#import "SPTSenTestCase.h"
#import <objc/runtime.h>

// http://clang.llvm.org/docs/Block-ABI-Apple.html
struct SPT_Block_literal_1 {
  void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
  int flags;
  int reserved;
  void (*invoke)(void *, ...);
  struct Block_descriptor_1 {
    unsigned long int reserved;	// NULL
    unsigned long int size;     // sizeof(struct Block_literal_1)
    // optional helper functions
    void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    void (*dispose_helper)(void *src);             // IFF (1<<25)
    // required ABI.2010.3.16
    const char *signature;                         // IFF (1<<30)
  } *descriptor;
  // imported variables
};

enum {
  SPT_BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
  SPT_BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
  SPT_BLOCK_IS_GLOBAL =         (1 << 28),
  SPT_BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
  SPT_BLOCK_HAS_SIGNATURE =     (1 << 30),
};

const char *SPT_getBlockSignature(id blockObject) {
  struct SPT_Block_literal_1 *block = (struct SPT_Block_literal_1 *)blockObject;

  int flags = block->flags;

  if(flags & SPT_BLOCK_HAS_SIGNATURE) {
    void *signaturePtr = block->descriptor;
    signaturePtr += sizeof(unsigned long int); // skip reserved
    signaturePtr += sizeof(unsigned long int); // skip size

    if(flags & SPT_BLOCK_HAS_COPY_DISPOSE) {
      signaturePtr += sizeof(void(*)(void *dst, void *src)); // skip copy_helper
      signaturePtr += sizeof(void(*)(void *dst, void *src)); // skip dispose_helper
    }

    return *(const char **)signaturePtr;
  }

  return NULL;
}

BOOL SPT_IsSpecClass(Class aClass)
{
  Class superclass = class_getSuperclass(aClass);
  while (superclass != Nil) {
    if (superclass == [SPTSenTestCase class]) {
      return YES;
    } else {
      superclass = class_getSuperclass(superclass);
    }
  }
  return NO;
}
