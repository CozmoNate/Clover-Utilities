//
//  Test.h
//  Test
//
//  Created by Kozlek on 18/05/13.
//  Copyright (c) 2013 Kozlek. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface Test : SenTestCase
{
    io_registry_entry_t _ioAcpiPlatformExpert;
    
    NSDictionary *_diskutilList;
    NSArray *_efiPartitions;
}

@end
