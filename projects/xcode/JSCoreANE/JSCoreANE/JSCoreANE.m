//
//  JSCoreANE.m
//  JSCoreANE
//
//  Created by admin on 21.10.14.
//  Copyright (c) 2014 PeyTy. All rights reserved.
//

#import "JSCoreANE.h"
#import "FlashRuntimeExtensions.h"
#import <JavaScriptCore/JavaScriptCore.h>

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

#define MAP_FUNCTION_NAMED(named, fn, data) { named, (data), &(fn) }

#define DISPATCH_STATUS_EVENT(extensionContext, code, level) FREDispatchStatusEventAsync((extensionContext), (uint8_t*)code, (uint8_t*)level)


@implementation JSCoreANE

@end

// Globalvar
JSGlobalContextRef jsctx;

DEFINE_ANE_FUNCTION(ADEPEval)
{
    // To be filled
    uint32_t string1Length;
    const uint8_t *string1;
    FREGetObjectAsUTF8(argv[0], &string1Length, &string1);
    
    // Evaluate script.
    JSStringRef scriptJS = JSStringCreateWithUTF8CString(string1);
    //JSStringCreateWithCharacters(string1, string1Length);
    JSEvaluateScript(jsctx, scriptJS, NULL, NULL, 0, NULL);
    JSStringRelease(scriptJS);
    return NULL;
}

DEFINE_ANE_FUNCTION(ADEPCall)
{
    // To be filled
    uint32_t string1Length;
    const uint8_t *string1;
    FREGetObjectAsUTF8(argv[0], &string1Length, &string1);
    
    // Evaluate script.
    JSStringRef scriptJS = JSStringCreateWithUTF8CString(string1);
    JSValueRef result = JSEvaluateScript(jsctx, scriptJS, NULL, NULL, 0, NULL);
    JSStringRelease(scriptJS);
    
    // Convert result to string
    size_t bufferSize;
    char* buffer;
    
    JSStringRef resultStringJS = JSValueToStringCopy(jsctx, result, NULL);
    bufferSize = JSStringGetMaximumUTF8CStringSize(resultStringJS);
    buffer = malloc(bufferSize);
    JSStringGetUTF8CString(resultStringJS, buffer, bufferSize);
    JSStringRelease(resultStringJS);
    
    FREObject retVal;
    FRENewObjectFromUTF8(bufferSize, (const uint8_t*)buffer, &retVal);
    free(buffer);
    return retVal;
}

// A native context instance is created
void ExtensionContextInitializer(void* extData,
                                     const uint8_t* ctxType,
                                     FREContext ctx,
                                     uint32_t* numFunctionsToSet,
                                     const FRENamedFunction** functionsToSet){
  
    // Initialize the native context.
    static FRENamedFunction functionMap[] =
    {
        MAP_FUNCTION_NAMED((const uint8_t*)"eval", ADEPEval, NULL),
        MAP_FUNCTION_NAMED((const uint8_t*)"call", ADEPCall, NULL)
    };
    
    *numFunctionsToSet = sizeof( functionMap ) / sizeof( FRENamedFunction );
	*functionsToSet = functionMap;
    
    // Load JSC
    // Create JavaScript execution context.
    jsctx = JSGlobalContextCreate(NULL);
    // Initial script
    JSStringRef scriptJS = JSStringCreateWithUTF8CString("window = {};");
    // Evaluate script.
    JSEvaluateScript(jsctx, scriptJS, NULL, NULL, 0, NULL);
    JSStringRelease(scriptJS);
}

void ExtensionContextFinalizer(FREContext ctx)
{
	// Release JavaScript execution context.
    JSGlobalContextRelease(jsctx);
}

// Initialization function of each extension
void JSCoreANEExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet) {
	*extDataToSet = NULL;
	*ctxInitializerToSet = &ExtensionContextInitializer;
	*ctxFinalizerToSet = &ExtensionContextFinalizer;
}

// Called when extension is unloaded
void JSCoreANEExtensionFinalizer(void* extData) {
	return;
}