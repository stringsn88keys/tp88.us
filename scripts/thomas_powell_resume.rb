class ThomasPowell
  attr_reader :name, :title, :website, :objective, :skills, :experience, :education, :certifications

  def initialize
    @name = "Thomas Powell"
    @title = "Senior Technical Leader"
    @website = "https://thomaspowell.com/about"
    @objective = "Dedicated and experienced Senior Software Engineering Manager looking for the opportunity to bring 20+ years' experience with programming, architecture, technology engineering, and leadership to a Software Engineering Manager role."
    @skills = [
      "Team Leadership",
      "Legacy Apps Support", 
      "Ruby/Rails 10 years",
      "AWS Certified Solutions Architect -- Professional and 4X certified",
      "Healthcare Tech",
      "Restaurant POS and BOH"
    ]
    @experience = build_experience
    @education = build_education
    @certifications = build_certifications
  end

  private

  def build_experience
    [
      {
        title: "Senior Principal Engineer",
        company: "Progress, Chef Infra Client",
        duration: "05/2022 - Present",
        responsibilities: [
          "Troubleshooting Windows builds for Chef 18 release and stabilizing the build",
          "Community PR and Issue Triage",
          "Ad Hoc Jobs architecture and development in Golang",
          "Solve complex to set up and trace problems, often with Ruby, packaging, and our target operating systems:",
          {
            aix: "building of libarchive (https://github.com/chef/omnibus-software/issues/1566)",
            windows: [
              "Solving heap memory error with UCRT in invoking PowerShell from Ruby through C++/CLI (https://github.com/chef/chef-powershell-shim/pull/187)",
              "Resolving OpenSSL FIPS fingerprint error by invoking /DYNAMICBASE:NO in linker (https://github.com/chef/omnibus-software/pull/1738/files)",
              "Fix error loading time zones and output from popen/%x due to encoding issues (https://github.com/chef/ohai/pull/1781)",
              "Traced Chinese Windows version install segmentation faults to misidentification of 32-bit vs. 64-bit architectures on multiple language versions"
            ],
            solaris: "Find a solution for a mismatch between Solaris patch version of customer fleets and internal build systems (pkgmogrify) (https://github.com/chef/omnibus/pull/1144)"
          }
        ]
      },
      {
        title: "Sr Software Engineer / Support Team Lead",
        company: "Everly Health",
        duration: "03/2021 -- 04/2022",
        responsibilities: [
          "Mentoring new junior engineers in support, ActiveRecord and SQL queries, and DevOps",
          "Mirth and HL7 messaging support",
          "Prioritization of support concerns and analysis of top candidates for automation",
          "Legacy Rails app Labs Module enhancements and build stabilization, providing feedback on the Git workflow and Release process",
          "Compass Project adding Rack::Middleware and log formatters to filter sensitive data from being sent to the logs",
          "Datica to LogicWorks (on EKS) migration, focusing on helm charts and configuration of ingress and Datadog ingest",
          "Configuring monitoring dashboards and improvements to Statuspage.io integration for uptime with Datadog"
        ]
      },
      {
        title: "SR Software Engineering Manager",
        company: "Appriss Health",
        duration: "08/2018 -- 03/2021",
        responsibilities: [
          "Remote manager of a team of up to 13 remote US and Warsaw-based developers",
          "Architecture Design Sessions for tech debt",
          "Rails 5 Upgrade",
          "Interviewing of Director of Engineering, Manager, and Software Engineering candidates",
          "Migration of Legacy Prescription Management Program monolith new functionality to Vue.js",
          "Debugged platform/performance issues with Platform team, utilizing New Relic and AWS Performance Insights",
          "Conduct 1:1 with direct reports and manage performance and career development",
          "Manager of Site Reliability Engineering team, tuning alerting with Sumologic and New Relic"
        ]
      },
      {
        title: "Software Engineer III -- IV",
        company: "Appriss Health",
        duration: "07/2012 -- 08/2018",
        responsibilities: [
          "Co-developed flagship Prescription Management Program monolith in Ruby on Rails that ultimately served 43 distinct state configurations, scaling to billions of rows of data in PostgreSQL",
          "Co-developed Prescription Management Program API Gateway that provided integration points for pharmacies and health systems",
          "Led team that developed a Medical Marijuana Registry for Ohio",
          "Led team of 1-3 developers to launch a pilot of a Xamarin mobile app for overdose entry + accompanying backend utilizing AWS Cognito and React + .NET core frontend",
          "Led team book reads and discussions of books such as Exceptional Ruby and POODR"
        ]
      },
      {
        title: "Intern to Solutions Architect",
        company: "Yum Brands",
        duration: "05/1996 -- 07/2012",
        responsibilities: [
          "Promoted to multiple roles; from co-op student writing C and debugging assembly to Project Lead, Applications Analyst, and Solutions Architect; working with IT directors and executives on technology research and strategy",
          "Java developer supporting EAI processes built on JCAPS 6/Java Web Services/JMS/DB2, some Spring MVC POC",
          "Solutions Architecture, including: training leadership teams on use of social media platforms and concepts, Analysis of Microsoft BI toolset for China division, Lead on Mobile ordering proof of concept with POS integration",
          "Enterprise Search with IBM OmniFind integration to SharePoint and WebSphere C#.NET team lead for Labor and Sales Forecasting engine migration of SQL Server queries and stored procedures from KFC business rules to Long John Silver's business rules",
          "Credit card and gift card POS integration and business analyst for flagship projects with Pizza Hut division"
        ]
      }
    ]
  end

  def build_education
    [
      {
        degree: "Master of Engineering, Computer Engineering Computer Science",
        school: "University of Louisville",
        graduation: "Fall 2003",
        honors: "Graduated with Honors"
      },
      {
        degree: "Bachelor of Science, Engineering Mathematics and Computer Science",
        school: "University of Louisville",
        graduation: "Spring 2000"
      }
    ]
  end

  def build_certifications
    [
      {
        name: "AWS Certified Solutions Architect Professional (SAP-C01)",
        achieved: "3/21/2022"
      },
      {
        name: "AWS SysOps Administrator Associate (SOA-C01)",
        achieved: "03/23/2021"
      },
      {
        name: "AWS Certified Developer Associate (DVA-C01)",
        achieved: "01/26/2021"
      },
      {
        name: "AWS Certified Solutions Architect Associate (SAA-C02)",
        achieved: "12/1/2020"
      }
    ]
  end

  public

  def years_of_experience
    current_year = Time.now.year
    start_year = 1996
    current_year - start_year
  end

  def current_role
    @experience.first
  end

  def aws_certifications
    @certifications.select { |cert| cert[:name].include?("AWS") }
  end

  def management_experience
    @experience.select { |job| job[:title].downcase.include?("manager") || job[:title].downcase.include?("lead") }
  end

  def technical_skills
    @skills.select { |skill| !skill.include?("Leadership") && !skill.include?("Support") }
  end

  def leadership_skills
    @skills.select { |skill| skill.include?("Leadership") || skill.include?("Support") }
  end

  def summary
    "#{@name} is a #{@title} with #{years_of_experience} years of experience in software engineering, architecture, and team leadership. Currently working as a #{current_role[:title]} at #{current_role[:company]}."
  end

  def to_s
    summary
  end
end

# Usage example:
# thomas = ThomasPowell.new
# puts thomas.summary
# puts "AWS Certifications: #{thomas.aws_certifications.count}"
# puts "Management Experience: #{thomas.management_experience.count} roles"