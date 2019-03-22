![](https://github.com/Microsoft/MCW-Template-Cloud-Workshop/raw/master/Media/ms-cloud-workshop.png "Microsoft Cloud Workshops")

<div class="MCWHeader1">
Azure Migration
</div>

<div class="MCWHeader2">
Whiteboard design session student guide
</div>

<div class="MCWHeader3">
March 2019
</div>


Information in this document, including URL and other Internet Web site references, is subject to change without notice. Unless otherwise noted, the example companies, organizations, products, domain names, e-mail addresses, logos, people, places, and events depicted herein are fictitious, and no association with any real company, organization, product, domain name, e-mail address, logo, person, place or event is intended or should be inferred. Complying with all applicable copyright laws is the responsibility of the user. Without limiting the rights under copyright, no part of this document may be reproduced, stored in or introduced into a retrieval system, or transmitted in any form or by any means (electronic, mechanical, photocopying, recording, or otherwise), or for any purpose, without the express written permission of Microsoft Corporation.

Microsoft may have patents, patent applications, trademarks, copyrights, or other intellectual property rights covering subject matter in this document. Except as expressly provided in any written license agreement from Microsoft, the furnishing of this document does not give you any license to these patents, trademarks, copyrights, or other intellectual property.

The names of manufacturers, products, or URLs are provided for informational purposes only and Microsoft makes no representations and warranties, either expressed, implied, or statutory, regarding these manufacturers or the use of the products with any Microsoft technologies. The inclusion of a manufacturer or product does not imply endorsement of Microsoft of the manufacturer or product. Links may be provided to third party sites. Such sites are not under the control of Microsoft and Microsoft is not responsible for the contents of any linked site or any link contained in a linked site, or any changes or updates to such sites. Microsoft is not responsible for webcasting or any other form of transmission received from any linked site. Microsoft is providing these links to you only as a convenience, and the inclusion of any link does not imply endorsement of Microsoft of the site or the products contained therein.

© 2019 Microsoft Corporation. All rights reserved.

Microsoft and the trademarks listed at <https://www.microsoft.com/en-us/legal/intellectualproperty/Trademarks/Usage/General.aspx> are trademarks of the Microsoft group of companies. All other trademarks are property of their respective owners.

**Contents**

<!-- TOC -->

- [Azure migration whiteboard design session student guide](#azure-migration-whiteboard-design-session-student-guide)
  - [Abstract and learning objectives](#abstract-and-learning-objectives)
  - [Step 1: Review the customer case study](#step-1-review-the-customer-case-study)
    - [Customer situation](#customer-situation)
    - [Customer needs](#customer-needs)
    - [Customer objections](#customer-objections)
    - [Infographic for common scenarios](#infographic-for-common-scenarios)
  - [Step 2: Design a proof of concept solution](#step-2-design-a-proof-of-concept-solution)
  - [Step 3: Present the solution](#step-3-present-the-solution)
  - [Wrap-up](#wrap-up)
  - [Additional references](#additional-references)

<!-- /TOC -->

#  Azure migration whiteboard design session student guide

## Abstract and learning objectives 

In this whiteboard design session, you will look at how to design an Azure migration for a heterogenous customer environment. The existing infrastructure comprises both Windows and Linux servers running on both VMWare and physical machines, and includes some legacy servers. Throughout the whiteboard design session, you will look at the various options and services available to migrate heterogenous environments to Azure.

At the end of this workshop, you will be better able to design and implement the discovery and assessment of environments to evaluate their readiness for migrating to Azure using services including Azure Migrate, Azure Database Migration Service, and Azure Site Recovery.


## Step 1: Review the customer case study 

**Outcome**

Analyze your customer's needs.

Timeframe: 15 minutes

Directions:  With all participants in the session, the facilitator/SME presents an overview of the customer case study along with technical tips.

1.  Meet your table participants and trainer.

2.  Read all of the directions for steps 1-3 in the student guide.

3.  As a table team, review the following customer case study.

### Customer situation

Fabrikam Fabrics is a major manufacturer and distributor of clothing and soft furnishing materials. Founded in 1972 and based in Columbus, Ohio, their business comprises three major product families (clothing, upholstery, and technical fabrics). Customers comprise familiar brand-name clothing manufacturers and furniture manufacturers, and also includes large-scale uniform suppliers to the US military. Turnover in 2018 exceeded 350 million USD.

The CTO, James Lynch, was hired 6 months ago from outside the company, with a mandate to address ever-increasing IT costs. He has identified a sprawling IT estate, including a substantial legacy server footprint. New servers and services have been accumulated over time, without consolidating existing infrastructure. This includes:
- Windows servers including both x32 and x64 hardware running Windows Server 2003 through to 2016
- Linux servers running a mix of RHEL 6.10 and 7 series (7.2 through 7.6) and Ubuntu 16.04
- The above servers comprise both physical machines as well as VMs hosted on VMware infrastructure managed by vCenter 6.5
- Multiple database engines, including Microsoft SQL Server, PostgreSQL, and Cassandra

In total, 448 servers and VMs have been identified to date, distributed across 5 main locations, all in the US. There is a complex web of dependencies between servers and no-one has a clear view of the entire estate. Fear of breaking an existing system has been one of the drivers of server count and sprawl.

To address this, James has proposed to the board that Fabrikam should migrate as much of the existing IT infrastructure as possible to the cloud. As well as eliminating IT infrastructure overheads, this will be an opportunity to 'clean house' and create a modern, fit-for-purpose IT environment. The board have agreed, and Microsoft Azure has been selected as the cloud provider.


### Customer needs 

1.  Identify which servers (physical and virtual) can be migrated to Azure, and what modifications (if any) are required
   
2.  Create a road map of prioritized migrations, accounting for ease of migration and dependencies

3.  Where suitable, migrate existing servers and databases to Azure as efficiently as possible
   
3.  Where existing servers cannot be migrated, identify alternative migration strategies (refactor, re-architect, etc) and their pros/cons
   
4.  Prior to migration, accurately forecast the costs associated with each migrated workload, including any third-party licensing costs
   
5.  Post-migration, be able to track costs, control usage, cross-charge business owners, and identify cost-saving opportunities
   

### Customer objections 

1.  Owners of each business application need to approve any substantial application change, including migration. Business owners have indicated that they will require evidence that migration will be successful before granting approval.

2.  Fabrikam have negotiated an Enterprise Agreement (EA) with Microsoft for their Azure consumption. Any cost estimates need to reflect their EA discount.

3.  Many applications comprise multiple components or tiers. How can you ensure that these migrations are appropriately orchestrated?
   
4.  To reduce business impact, each migration should be designed to minimize application downtime. In addition, to reduce risk, there must be an option to fail-back should the migration experience an unexpected problem.


### Infographic for common scenarios

![Common scenarios include: Azure Migrate, Azure Site Recovery, and Azure Database Migration Service](images/common_scenarios.png)

## Step 2: Design a proof of concept solution

**Outcome**

Design a solution and prepare to present the solution to the target customer audience in a 15-minute chalk-talk format.

Timeframe: 60 minutes

**Business needs**

Directions: With all participants at your table, answer the following questions and list the answers on a flip chart:

1.  Who should you present this solution to? Who is your target customer audience? Who are the decision makers?

2.  What customer business needs do you need to address with your solution?

**Design**

Directions: With all participants at your table, respond to the following questions on a flip chart:


*Migration Assessment*

1.  How can Fabrikam assess their existing infrastructure for migration to Azure? Provide options for VMware VMs, physical servers, and databases.

2.  How can Fabrikam identify dependencies between their existing servers? How can they use this information in their migration planning?
   
3.  What criteria should Fabrikam use to prioritize their migrations when building a migration road map?
   
4.  What options can you suggest to migrate workloads whose current infrastructure is not suitable for a lift-and-shift migration to Azure? 


*Migration Execution*

5.  What Azure components or configurations should be deployed prior to migration?

6.  What tools are available for migration execution? Provide options for VMware VMs, physical servers, and databases.
   
7.  What post-migration steps should be carried out for business-critical applications migrated to Azure?


*Cost management and optimization*

8.  How can Fabrikam estimate the future cost before a workload is migrated to Azure?
   
9.  How can Fabrikam optimize their cost estimate, prior to migration?
   
10. How can Fabrikam analyze and optimize their costs, post-migration? Include details of mechanisms for internal charge-back.

**Prepare**

Directions: With all participants at your table:

1.  Identify any customer needs that are not addressed with the proposed solution.

2.  Identify the benefits of your solution.

3.  Determine how you will respond to the customer's objections.

Prepare a 15-minute chalk-talk style presentation to the customer.

## Step 3: Present the solution

**Outcome**

Present a solution to the target customer audience in a 15-minute chalk-talk format.

Timeframe: 30 minutes

**Presentation**

Directions:

1.  Pair with another table.

2.  One table is the Microsoft team and the other table is the customer.

3.  The Microsoft team presents their proposed solution to the customer.

4.  The customer makes one of the objections from the list of objections.

5.  The Microsoft team responds to the objection.

6.  The customer team gives feedback to the Microsoft team.

7.  Tables switch roles and repeat Steps 2-6.

##  Wrap-up 

Timeframe: 15 minutes

Directions: Tables reconvene with the larger group to hear the facilitator/SME share the preferred solution for the case study.

##  Additional references

|    |            |
|----------|:-------------:|
| **Description** | **Links** |
| Azure migration hub  | https://azure.microsoft.com/migration/  |
| Azure Migrate  | https://azure.microsoft.com/services/azure-migrate/  |
| Azure Site Recovery  | https://azure.microsoft.com/services/site-recovery/ |
| Azure Database Migration Guide  | https://aka.ms/datamigration  |
| Microsoft Data Migration Assistant (DMA) | https://docs.microsoft.com/sql/dma/dma-overview?view=sql-server-2017 |
| Azure Data Migration Service | https://azure.microsoft.com/services/database-migration/ |
| Azure SQL Database | https://azure.microsoft.com/services/sql-database/ |
| Azure billing hub | https://docs.microsoft.com/azure/billing/ |
| Azure cost management | https://azure.microsoft.com/services/cost-management/ |
| Azure governance | https://azure.microsoft.com/solutions/governance/ |
| Azure advisor | https://azure.microsoft.com/services/advisor/ |
| Azure enterprise scaffold | https://docs.microsoft.com/azure/architecture/cloud-adoption/appendix/azure-scaffold |
| Azure virtual datacenter | https://docs.microsoft.com/azure/architecture/vdc/ |

