//
//  GMPersistentController.m
//  imem
//
//  Created by LuoBin on 14-8-13.
//
//

#import "GMPersistentStoreController.h"
#import <CoreData/CoreData.h>

#define kEntityName @"GmAddress"
#define kAttributeName @"addressObj"

@interface GmAddress : NSManagedObject<Adderss>

@property (nonatomic, retain, readwrite) NSNumber *addressObj;

@end

@implementation GmAddress

@dynamic addressObj;

- (void)dealloc {
    self.addressObj = nil;
    [super dealloc];
}

- (uint64_t)address {
    return [self.addressObj unsignedLongLongValue];
}

@end


@interface GMPersistentStoreController()

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator ;

@end

@implementation GMPersistentStoreController

+ (instancetype)shareInstance {
    static GMPersistentStoreController *sharedInstance = nil;
    if (!sharedInstance) {
        @synchronized(self){
            if (!sharedInstance) {
                sharedInstance = [[GMPersistentStoreController alloc] init];
            }
        }
    }
    return sharedInstance;
}

- (NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return _managedObjectContext;
}

//2
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSEntityDescription *entityDescription = [[[NSEntityDescription alloc] init] autorelease];
    entityDescription.name = kEntityName;
    entityDescription.managedObjectClassName = kEntityName;
    
    NSAttributeDescription *addressDescription  = [[[NSAttributeDescription alloc] init] autorelease];
    addressDescription.name = kAttributeName;
    addressDescription.attributeType = NSInteger64AttributeType;
    
    entityDescription.properties = @[addressDescription];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] init];
    [_managedObjectModel setEntities:@[entityDescription]];
    
    return _managedObjectModel;
}

//3
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"imem.sqlite"]];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:[self managedObjectModel]];
    if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil URL:storeUrl options:nil error:&error]) {
        /*Error for store creation should be handled in here*/
        NSLog(@"addPersistentStore error：%@", error);
    }
    
    return _persistentStoreCoordinator;
}

- (NSString *)applicationDocumentsDirectory {
    NSString *documentPath = @"/private/var/mobile/Documents";
    NSString *path = [documentPath stringByAppendingPathComponent:@"com.binge.imem.daemon/"];
    return path;
}

- (void)insertObject:(uint64_t)address {
    GmAddress *addressObj = [NSEntityDescription insertNewObjectForEntityForName:kEntityName inManagedObjectContext:self.managedObjectContext];
    addressObj.addressObj = @(address);
    [self.managedObjectContext insertObject:addressObj];
}

- (void)deleteObject:(id)address {
    [self.managedObjectContext deleteObject:address];
}

- (BOOL)save:(NSError **)error {
    if (![self.managedObjectContext save:error]) {
        NSLog(@"save error.%@", *error);
        return NO;
    }
    return YES;
}

- (void)truncateAll {
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"imem.sqlite"]];
    [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:nil];

    if (_persistentStoreCoordinator) {
        NSArray *stores = [_persistentStoreCoordinator persistentStores];
        
        for(NSPersistentStore *store in stores) {
            [self.persistentStoreCoordinator removePersistentStore:store error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
        }
        NSError *error = nil;
        if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil URL:storeUrl options:nil error:&error]) {
            /*Error for store creation should be handled in here*/
            NSLog(@"addPersistentStore error：%@", error);
        }
    }
}

- (NSArray *)fetchObjectWithOffset:(int)offset size:(int)size {
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] initWithEntityName:kEntityName] autorelease];
    fetchRequest.fetchOffset = offset;
    fetchRequest.fetchLimit = size;
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:kAttributeName ascending:YES] autorelease];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"FetchRequest error:%@", error);
        return nil;
    }
    return result;
}

@end
