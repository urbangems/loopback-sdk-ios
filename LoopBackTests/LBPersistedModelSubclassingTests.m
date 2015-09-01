//
//  LBPersistedModelSubclassingTest.m
//  LoopBack
//
//  Created by Michael Schoonmaker on 6/19/13.
//  Copyright (c) 2013 StrongLoop. All rights reserved.
//

#import "LBPersistedModelSubclassingTests.h"

#import "LBModel.h"
#import "LBRESTAdapter.h"

static NSNumber *lastId;

@interface Widget : LBPersistedModel

@property (nonatomic, copy) NSString *name;
// a Number property can be accessed via either of NSNumber or the primitive type long.
@property (nonatomic) NSNumber *bars;
@property long bars2;
// a Boolean property can be accessed via either of NSNumber or the primitive type BOOL.
@property (nonatomic) NSNumber *flag;
@property BOOL flag2;
@end

@implementation Widget

@end

@interface WidgetRepository : LBPersistedModelRepository
+ (instancetype)repository;

@end

@implementation WidgetRepository

+ (instancetype)repository {
    return [self repositoryWithClassName:@"widgets"];
}

@end

@interface LBPersistedModelSubclassingTests()

@property (nonatomic) WidgetRepository *repository;

@end

@implementation LBPersistedModelSubclassingTests

/**
 * Create the default test suite to control the order of test methods
 */
+ (id)defaultTestSuite {
    XCTestSuite *suite = [XCTestSuite testSuiteWithName:@"TestSuite for LBModel subclasses."];
    [suite addTest:[self testCaseWithSelector:@selector(testCreate)]];
    [suite addTest:[self testCaseWithSelector:@selector(testFind)]];
    [suite addTest:[self testCaseWithSelector:@selector(testAll)]];
    [suite addTest:[self testCaseWithSelector:@selector(testUpdate)]];
    [suite addTest:[self testCaseWithSelector:@selector(testRemove)]];
    return suite;
}

- (void)setUp {
    [super setUp];

    LBRESTAdapter *adapter = [LBRESTAdapter adapterWithURL:[NSURL URLWithString:@"http://localhost:3000"]];
    self.repository = (WidgetRepository *)[adapter repositoryWithClass:[WidgetRepository class]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCreate {
    Widget *model = (Widget*)[self.repository modelWithDictionary:@{
        @"name" : @"Foobar",
        @"bars" : @123,
        @"bars2": @123,
        @"flag" : @YES,
        @"flag2": @YES
    }];

    XCTAssertNil(model._id, @"Invalid id");
    XCTAssertEqualObjects(model.name, @"Foobar", @"Invalid name.");
    XCTAssertEqualObjects(model.bars, @123, @"Invalid bars.");
    XCTAssertEqual(model.bars2, 123, @"Invalid bars2.");
    XCTAssertEqualObjects(model.flag, @YES, @"Invalid flag.");
    XCTAssertEqual(model.flag2, YES, @"Invalid flag2.");

    model.bars = @456;
    model.bars2 = 456;
    model.flag = @NO;
    model.flag2 = NO;

    XCTAssertEqualObjects(model.bars, @456, @"Invalid bars.");
    XCTAssertEqual(model.bars2, 456, @"Invalid bars2.");
    XCTAssertEqualObjects(model.flag, @NO, @"Invalid flag.");
    XCTAssertEqual(model.flag2, NO, @"Invalid flag2.");

    ASYNC_TEST_START
    [model saveWithSuccess:^{
        lastId = model._id;
        XCTAssertNotNil(model._id, @"Invalid id");
        ASYNC_TEST_SIGNAL
    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testFind {
    ASYNC_TEST_START
    [self.repository findById:@2
                       success:^(LBModel *model) {
                           XCTAssertNotNil(model, @"No model found with ID 2");
                           XCTAssertTrue([[model class] isSubclassOfClass:[Widget class]], @"Invalid class.");
                           XCTAssertEqualObjects(((Widget *)model).name, @"Bar", @"Invalid name");
                           XCTAssertEqualObjects(((Widget *)model).bars, @1, @"Invalid bars");
                           ASYNC_TEST_SIGNAL
                       } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testAll {
    ASYNC_TEST_START
    [self.repository allWithSuccess:^(NSArray *models) {
        XCTAssertNotNil(models, @"No models returned.");
        XCTAssertTrue([models count] >= 2, @"Invalid # of models returned: %lu", (unsigned long)[models count]);
        XCTAssertTrue([[models[0] class] isSubclassOfClass:[Widget class]], @"Invalid class.");
        XCTAssertEqualObjects(((Widget *)models[0]).name, @"Foo", @"Invalid name.");
        XCTAssertEqualObjects(((Widget *)models[0]).bars, @0, @"Invalid bars");
        XCTAssertEqualObjects(((Widget *)models[1]).name, @"Bar", @"Invalid name");
        XCTAssertEqualObjects(((Widget *)models[1]).bars, @1, @"Invalid bars");
        ASYNC_TEST_SIGNAL
    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testUpdate {
    ASYNC_TEST_START
    LBPersistedModelFindSuccessBlock verify = ^(LBPersistedModel *model) {
        XCTAssertNotNil(model, @"No model found with ID 2");
        XCTAssertTrue([[model class] isSubclassOfClass:[Widget class]], @"Invalid class.");
        XCTAssertEqualObjects(((Widget *)model).name, @"Barfoo", @"Invalid name");
        XCTAssertEqualObjects(((Widget *)model).bars, @1, @"Invalid bars");

        ((Widget *)model).name = @"Bar";
        [model saveWithSuccess:^{
            ASYNC_TEST_SIGNAL
        } failure:ASYNC_TEST_FAILURE_BLOCK];
    };

    LBPersistedModelSaveSuccessBlock findAgain = ^() {
        [self.repository findById:@2 success:verify failure:ASYNC_TEST_FAILURE_BLOCK];
    };

    LBPersistedModelFindSuccessBlock update = ^(LBPersistedModel *model) {
        XCTAssertNotNil(model, @"No model found with ID 2");
        ((Widget *)model).name = @"Barfoo";
        [model saveWithSuccess:findAgain failure:ASYNC_TEST_FAILURE_BLOCK];
    };

    [self.repository findById:@2 success:update failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testRemove {
    ASYNC_TEST_START
    [self.repository findById:lastId
                      success:^(LBPersistedModel *model) {
                          [model destroyWithSuccess:^{
                              ASYNC_TEST_SIGNAL
                          } failure:ASYNC_TEST_FAILURE_BLOCK];
                      } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}


@end
