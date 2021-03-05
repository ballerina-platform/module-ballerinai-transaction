Ballerina Transaction Internal Module
=====================================

  [![Build](https://github.com/ballerina-platform/module-ballerinai-transaction/workflows/Build/badge.svg)](https://github.com/ballerina-platform/module-ballerinai-transaction/actions?query=workflow%3ABuild)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinai-transaction.svg)](https://github.com/ballerina-platform/module-ballerinai-transaction/commits/master)
    [![Github issues](https://img.shields.io/github/issues/ballerina-platform/module-ballerinai-transaction.svg?label=Open%20Issues)](https://github.com/ballerina-platform/module-ballerinai-transaction/issues)
  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerinai-transaction/branch/master/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerinai-transaction)

The transaction internal module is a dependency module which required for Ballerina transactions. This internal
 module is depend on a few other ballerina std-libs such as http, io, config and system.

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).
   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
   * [OpenJDK](http://openjdk.java.net/install/index.html)

2. Export Github Personal access token with read package permissions as follows,
        
        export packageUser=<Username>
        export packagePAT=<Personal access token>

### Building the Source

Execute the commands below to build from the source.

1. To build the library:
        
        ./gradlew clean build

2. To run the integration tests:

        ./gradlew clean test

3. To build the module without tests:

        ./gradlew clean build -x test

4. To debug the tests:

        ./gradlew clean build -Pdebug=<port>

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
