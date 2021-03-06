#ifndef __APPLE_API_PRIVATE
#define __APPLE_API_PRIVATE
#include "sandbox.h"
#undef __APPLE_API_PRIVATE
#else
#include "sandbox.h"
#endif

#ifndef LIGHTMESSAGING_USE_ROCKETBOOTSTRAP
#define LIGHTMESSAGING_USE_ROCKETBOOTSTRAP 1
#endif

#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#include <mach/mach.h>
#include <mach/mach_init.h>
#if LIGHTMESSAGING_USE_ROCKETBOOTSTRAP
#include "rocketbootstrap.h"
#else
#include "bootstrap.h"
#endif

#if !TARGET_IPHONE_SIMULATOR

  uint32_t LMBufferSizeForLength(uint32_t length)
{
	if (length + sizeof(LMMessage) > __LMMaxInlineSize)
		return sizeof(LMMessage);
	else
		return ((sizeof(LMMessage) + length) + 3) & ~0x3;
}

  void LMMessageCopyInline(LMMessage *message, const void *data, uint32_t length)
{
	message->data.in_line.length = length;
	if (data) {
		memcpy(message->data.in_line.bytes, data, length);
	}
}

  void LMMessageAssignOutOfLine(LMMessage *message, const void *data, uint32_t length)
{
	message->head.msgh_bits |= MACH_MSGH_BITS_COMPLEX;
	message->body.msgh_descriptor_count = 1;
	message->data.out_of_line.descriptor.type = MACH_MSG_OOL_DESCRIPTOR;
	message->data.out_of_line.descriptor.copy = MACH_MSG_VIRTUAL_COPY;
	message->data.out_of_line.descriptor.deallocate = false;
	message->data.out_of_line.descriptor.address = (void *)data;
	message->data.out_of_line.descriptor.size = length;
}

  void LMMessageAssignData(LMMessage *message, const void *data, uint32_t length)
{
	if (length == 0) {
		message->body.msgh_descriptor_count = 0;
		message->data.in_line.length = length;
	} else if (message->head.msgh_size != sizeof(LMMessage)) {
		message->body.msgh_descriptor_count = 0;
		message->data.in_line.length = length;
		memcpy(message->data.in_line.bytes, data, length);
	} else {
		LMMessageAssignOutOfLine(message, data, length);
	}
}

  void *LMMessageGetData(LMMessage *message)
{
	if (message->body.msgh_descriptor_count)
		return message->data.out_of_line.descriptor.address;
	if (message->data.in_line.length == 0)
		return NULL;
	return &message->data.in_line.bytes;
}

  uint32_t LMMessageGetDataLength(LMMessage *message)
{
	if (message->body.msgh_descriptor_count)
		return message->data.out_of_line.descriptor.size;
	uint32_t result = message->data.in_line.length;
	// Clip to the maximum size of a message buffer, prevents clients from forcing reads outside the region
	if (result > __LMMaxInlineSize - offsetof(LMMessage, data.in_line.bytes))
		return __LMMaxInlineSize - offsetof(LMMessage, data.in_line.bytes);
	// Client specified the right size, yay!
	return result;
}

  mach_msg_return_t LMMachMsg(LMConnection *connection, mach_msg_header_t *msg, mach_msg_option_t option, mach_msg_size_t send_size, mach_msg_size_t rcv_size, mach_port_name_t rcv_name, mach_msg_timeout_t timeout, mach_port_name_t notify)
{
	for (;;) {
		kern_return_t err;
		if (connection->serverPort == MACH_PORT_NULL) {
			mach_port_t selfTask = mach_task_self();
			if ((kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0) && (kCFCoreFoundationVersionNumber < 800.0)) {
				int sandbox_result = sandbox_check(getpid(), "mach-lookup", SANDBOX_FILTER_LOCAL_NAME | SANDBOX_CHECK_NO_REPORT, connection->serverName);
				if (sandbox_result) {
					return sandbox_result;
				}
			}
			// Lookup remote port
			mach_port_t bootstrap = MACH_PORT_NULL;
			task_get_bootstrap_port(selfTask, &bootstrap);
#if LIGHTMESSAGING_USE_ROCKETBOOTSTRAP
			err = rocketbootstrap_look_up(bootstrap, connection->serverName, &connection->serverPort);
#else
			err = bootstrap_look_up(bootstrap, connection->serverName, &connection->serverPort);
#endif
			if (err)
				return err;
		}
		msg->msgh_remote_port = connection->serverPort;
		err = mach_msg(msg, option, send_size, rcv_size, rcv_name, timeout, notify);
		if (err != MACH_SEND_INVALID_DEST)
			return err;
		mach_port_deallocate(mach_task_self(), msg->msgh_remote_port);
		connection->serverPort = MACH_PORT_NULL;
	}
}

  kern_return_t LMConnectionSendOneWay(LMConnectionRef connection, SInt32 messageId, const void *data, uint32_t length)
{
	// Send message
	uint32_t size = LMBufferSizeForLength(length);
	uint8_t buffer[size];
	LMMessage *message = (LMMessage *)&buffer[0];
	memset(message, 0, sizeof(LMMessage));
	message->head.msgh_id = messageId;
	message->head.msgh_size = size;
	message->head.msgh_local_port = MACH_PORT_NULL;
	message->head.msgh_reserved = 0;
	message->head.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, 0);
	LMMessageAssignData(message, data, length);
	return LMMachMsg(connection, &message->head, MACH_SEND_MSG, size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
}

  kern_return_t LMConnectionSendEmptyOneWay(LMConnectionRef connection, SInt32 messageId)
{
	// TODO: Optimize so we don't use the additional stack space
	uint32_t size = sizeof(mach_msg_header_t) + sizeof(mach_msg_body_t);
	LMMessage message;
	memset(&message, 0, size);
	message.head.msgh_id = messageId;
	message.head.msgh_size = size;
	message.head.msgh_local_port = MACH_PORT_NULL;
	message.head.msgh_reserved = 0;
	message.head.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, 0);
	return LMMachMsg(connection, &message.head, MACH_SEND_MSG, size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
}

  kern_return_t LMConnectionSendTwoWay(LMConnectionRef connection, SInt32 messageId, const void *data, uint32_t length, LMResponseBuffer *responseBuffer)
{
	// Create a reply port
	mach_port_t selfTask = mach_task_self();
	mach_port_name_t replyPort = MACH_PORT_NULL;
	int err = mach_port_allocate(selfTask, MACH_PORT_RIGHT_RECEIVE, &replyPort);
	if (err) {
		responseBuffer->message.body.msgh_descriptor_count = 0;
		return err;
	}
	// Send message
	uint32_t size = LMBufferSizeForLength(length);
	LMMessage *message = &responseBuffer->message;
	memset(message, 0, sizeof(LMMessage));
	message->head.msgh_id = messageId;
	message->head.msgh_size = size;
	message->head.msgh_local_port = replyPort;
	message->head.msgh_reserved = 0;
	message->head.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND_ONCE);
	LMMessageAssignData(message, data, length);
	err = LMMachMsg(connection, &message->head, MACH_SEND_MSG | MACH_RCV_MSG, size, sizeof(LMResponseBuffer), replyPort, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
	if (err)
		responseBuffer->message.body.msgh_descriptor_count = 0;
	// Cleanup
	mach_port_deallocate(selfTask, replyPort);
	return err;
}

  void LMResponseBufferFree(LMResponseBuffer *responseBuffer)
{
	if (responseBuffer->message.body.msgh_descriptor_count != 0 && responseBuffer->message.data.out_of_line.descriptor.type == MACH_MSG_OOL_DESCRIPTOR) {
		vm_deallocate(mach_task_self(), (vm_address_t)responseBuffer->message.data.out_of_line.descriptor.address, responseBuffer->message.data.out_of_line.descriptor.size);
		responseBuffer->message.body.msgh_descriptor_count = 0;
	}
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  kern_return_t LMStartServiceWithUserInfo(name_t serverName, CFRunLoopRef runLoop, CFMachPortCallBack callback, void *userInfo)
{
	// TODO: Figure out what the real interface is, implement service stopping, handle failures correctly
	mach_port_t bootstrap = MACH_PORT_NULL;
	task_get_bootstrap_port(mach_task_self(), &bootstrap);
	CFMachPortContext context = { 0, userInfo, NULL, NULL, NULL };
	CFMachPortRef machPort = CFMachPortCreate(kCFAllocatorDefault, callback, &context, NULL);
	CFRunLoopSourceRef machPortSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0);
	CFRunLoopAddSource(runLoop, machPortSource, kCFRunLoopCommonModes);
	mach_port_t port = CFMachPortGetPort(machPort);
#if LIGHTMESSAGING_USE_ROCKETBOOTSTRAP
	rocketbootstrap_unlock(serverName);
#endif
	return bootstrap_register(bootstrap, serverName, port);
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

  kern_return_t LMStartService(name_t serverName, CFRunLoopRef runLoop, CFMachPortCallBack callback)
{
	return LMStartServiceWithUserInfo(serverName, runLoop, callback, NULL);
}

  kern_return_t LMSendReply(mach_port_t replyPort, const void *data, uint32_t length)
{
	if (replyPort == MACH_PORT_NULL)
		return 0;
	uint32_t size = LMBufferSizeForLength(length);
	uint8_t buffer[size];
	memset(buffer, 0, sizeof(LMMessage));
	LMMessage *response = (LMMessage *)&buffer[0];
	response->head.msgh_id = 0;
	response->head.msgh_size = size;
	response->head.msgh_remote_port = replyPort;
	response->head.msgh_local_port = MACH_PORT_NULL;
	response->head.msgh_reserved = 0;
	response->head.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_MOVE_SEND_ONCE, 0);
	LMMessageAssignData(response, data, length);
	// Send message
	kern_return_t err = mach_msg(&response->head, MACH_SEND_MSG, size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
	if (err) {
		// Cleanup leaked SEND_ONCE
		mach_port_mod_refs(mach_task_self(), replyPort, MACH_PORT_RIGHT_SEND_ONCE, -1);
	}
	return err;
}

  kern_return_t LMSendIntegerReply(mach_port_t replyPort, int integer)
{
	return LMSendReply(replyPort, &integer, sizeof(integer));
}

  kern_return_t LMSendCFDataReply(mach_port_t replyPort, CFDataRef data)
{
	if (data) {
		return LMSendReply(replyPort, CFDataGetBytePtr(data), CFDataGetLength(data));
	} else {
		return LMSendReply(replyPort, NULL, 0);
	}
}

#ifdef __OBJC__

  kern_return_t LMSendNSDataReply(mach_port_t replyPort, NSData *data)
{
	return LMSendReply(replyPort, [data bytes], [data length]);
}

  kern_return_t LMSendPropertyListReply(mach_port_t replyPort, id propertyList)
{
	if (propertyList)
		return LMSendNSDataReply(replyPort, [NSPropertyListSerialization dataFromPropertyList:propertyList format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]);
	else
		return LMSendReply(replyPort, NULL, 0);
}

#endif

// Remote functions

  bool LMConnectionSendOneWayData(LMConnectionRef connection, SInt32 messageId, CFDataRef data)
{
	if (data)
		return LMConnectionSendOneWay(connection, messageId, CFDataGetBytePtr(data), CFDataGetLength(data)) == 0;
	else
		return LMConnectionSendOneWay(connection, messageId, NULL, 0) == 0;
}

  kern_return_t LMConnectionSendTwoWayData(LMConnectionRef connection, SInt32 messageId, CFDataRef data, LMResponseBuffer *buffer)
{
	if (data)
		return LMConnectionSendTwoWay(connection, messageId, CFDataGetBytePtr(data), CFDataGetLength(data), buffer);
	else
		return LMConnectionSendTwoWay(connection, messageId, NULL, 0, buffer);
}

  int32_t LMResponseConsumeInteger(LMResponseBuffer *buffer)
{
	LMResponseBufferFree(buffer);
	return LMMessageGetDataLength(&buffer->message) == sizeof(int) ? *(int32_t *)buffer->message.data.in_line.bytes : 0;
}

#ifdef __OBJC__

  kern_return_t LMConnectionSendTwoWayPropertyList(LMConnectionRef connection, SInt32 messageId, id propertyList, LMResponseBuffer *buffer)
{
	return LMConnectionSendTwoWayData(connection, messageId, propertyList ? (CFDataRef)[NSPropertyListSerialization dataFromPropertyList:propertyList format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL] : NULL, buffer);
}

  id LMResponseConsumePropertyList(LMResponseBuffer *buffer)
{
	uint32_t length = LMMessageGetDataLength(&buffer->message);
	id result;
	if (length) {
		CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, LMMessageGetData(&buffer->message), length, kCFAllocatorNull);
		result = [NSPropertyListSerialization propertyListFromData:(NSData *)data mutabilityOption:0 format:NULL errorDescription:NULL];
		CFRelease(data);
	} else {
		result = nil;
	}
	LMResponseBufferFree(buffer);
	return result;
}

  kern_return_t LMConnectionSendTwoWayArchiverObject(LMConnectionRef connection, SInt32 messageId, id<NSCoding> archiverObject, LMResponseBuffer *buffer)
{
	return LMConnectionSendTwoWayData(connection, messageId, archiverObject ? (CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:archiverObject] : NULL, buffer);
}

  kern_return_t LMSendArchiverObjectReply(mach_port_t replyPort, id<NSCoding> archiverObject)
{
	if (archiverObject)
		return LMSendNSDataReply(replyPort, [NSKeyedArchiver archivedDataWithRootObject:archiverObject]);
	else
		return LMSendReply(replyPort, NULL, 0);
}

  id<NSCoding> LMResponseConsumeArchiverObject(LMResponseBuffer *buffer)
{
	uint32_t length = LMMessageGetDataLength(&buffer->message);
	id result;
	if (length) {
		CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, LMMessageGetData(&buffer->message), length, kCFAllocatorNull);
        result = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)data];
		CFRelease(data);
	} else {
		result = nil;
	}
	LMResponseBufferFree(buffer);
	return result;
}

#ifdef UIKIT_EXTERN
#import <UIKit/UIImage.h>

static void LMCGDataProviderReleaseCallback(void *info, const void *data, size_t size)
{
	vm_deallocate(mach_task_self(), (vm_address_t)data, size);
}

  UIImage *LMResponseConsumeImage(LMResponseBuffer *buffer)
{
	if (buffer->message.body.msgh_descriptor_count != 0 && buffer->message.data.out_of_line.descriptor.type == MACH_MSG_OOL_DESCRIPTOR) {
		const void *bytes = buffer->message.data.out_of_line.descriptor.address;
		const LMImageMessage *message = (const LMImageMessage *)buffer;
		const LMImageHeader *header = &message->imageHeader;
		CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, buffer->message.data.out_of_line.descriptor.size, LMCGDataProviderReleaseCallback);
		if (provider) {
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGImageRef cgImage = CGImageCreate(header->width, header->height, header->bitsPerComponent, header->bitsPerPixel, header->bytesPerRow, colorSpace, header->bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
			CGColorSpaceRelease(colorSpace);
			CGDataProviderRelease(provider);
			if (cgImage) {
				UIImage *image;
				if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
					image = [UIImage imageWithCGImage:cgImage scale:header->scale orientation:header->orientation];
				} else {
					image = [UIImage imageWithCGImage:cgImage];
				}
				CGImageRelease(cgImage);
				return image;
			}
			return nil;
		}
	}
	LMResponseBufferFree(buffer);
	return nil;
}

typedef struct CGAccessSession *CGAccessSessionRef;

CGAccessSessionRef CGAccessSessionCreate(CGDataProviderRef provider);
void *CGAccessSessionGetBytePointer(CGAccessSessionRef session);
size_t CGAccessSessionGetBytes(CGAccessSessionRef session,void *buffer,size_t bytes);
void CGAccessSessionRelease(CGAccessSessionRef session);

  kern_return_t LMSendImageReply(mach_port_t replyPort, UIImage *image)
{
	if (replyPort == MACH_PORT_NULL)
		return 0;
	LMImageMessage buffer;
	memset(&buffer, 0, sizeof(buffer));
	buffer.response.head.msgh_id = 0;
	buffer.response.head.msgh_size = sizeof(buffer);
	buffer.response.head.msgh_remote_port = replyPort;
	buffer.response.head.msgh_local_port = MACH_PORT_NULL;
	buffer.response.head.msgh_reserved = 0;
	buffer.response.head.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_MOVE_SEND_ONCE, 0);
	CFDataRef imageData = NULL;
	CGAccessSessionRef accessSession = NULL;
	if (image) {
		CGImageRef cgImage = image.CGImage;
		if (cgImage) {
			buffer.imageHeader.width = CGImageGetWidth(cgImage);
			buffer.imageHeader.height = CGImageGetHeight(cgImage);
			buffer.imageHeader.bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
			buffer.imageHeader.bitsPerPixel = CGImageGetBitsPerPixel(cgImage);
			buffer.imageHeader.bytesPerRow = CGImageGetBytesPerRow(cgImage);
			buffer.imageHeader.bitmapInfo = CGImageGetBitmapInfo(cgImage);
			buffer.imageHeader.scale = [image respondsToSelector:@selector(scale)] ? [image scale] : 1.0f;
			buffer.imageHeader.orientation = image.imageOrientation;
			CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
			bool hasLoadedData = false;
			if (&CGAccessSessionCreate != NULL) {
				accessSession = CGAccessSessionCreate(dataProvider);
				if (accessSession) {
					void *pointer = CGAccessSessionGetBytePointer(accessSession);
					if (pointer) {
						LMMessageAssignOutOfLine(&buffer.response, pointer, buffer.imageHeader.bytesPerRow * buffer.imageHeader.height);
						hasLoadedData = true;
					}
				}
			}
			if (!hasLoadedData) {
				if (accessSession) {
					CGAccessSessionRelease(accessSession);
					accessSession = NULL;
				}
				imageData = CGDataProviderCopyData(dataProvider);
				if (imageData) {
					LMMessageAssignOutOfLine(&buffer.response, CFDataGetBytePtr(imageData), CFDataGetLength(imageData));
				}
			}
		}
	}
	// Send message
	kern_return_t err = mach_msg(&buffer.response.head, MACH_SEND_MSG, sizeof(buffer), 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
	if (err) {
		// Cleanup leaked SEND_ONCE
		mach_port_mod_refs(mach_task_self(), replyPort, MACH_PORT_RIGHT_SEND_ONCE, -1);
	}
	if (imageData) {
		CFRelease(imageData);
	}
	if (accessSession) {
		CGAccessSessionRelease(accessSession);
	}
	return err;
}

#endif

#endif

#endif
