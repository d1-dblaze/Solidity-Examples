pragma solidity ^0.5.8;

/*Project Overview:
Currently, students have to schedule a one-on-one appointment with an adviser to ver-
ify their fulfillment status for the certificate. This model is not a scalable solution if
thousands of students want to enroll in the certificate program. This DCC-Dapp will
save time for the students as well as the advisers, and streamline the certification pro-
cess for some. More important, the recording on the blockchain of transactions initi-
ated by interested stakeholders will be a valuable resource and institutional data for
future analytics for course planning, advisement, and resource planning.


In other words, any student in the undergraduate program can evaluate their
 Eligibility to enroll in the certificate and to plan their future courses
 Progress through the certificate program as they complete courses
 Certificate fulfillment status, including the GPA requirement, on completion of
all the course requirements
*/

contract DICCertification {
    uint256 private constant MINIMUM_GPA_REQUIRED =250;

    struct Student {
        uint256 personNumber; //Identity to link to the University centralized database
        //Prerequisite courses grades
        uint256 prereq115;
        uint256 prereq116;
        //Core courses grades
        uint256 core250;
        uint256 core486;
        uint256 core487;
        //Domain specific course;
        uint256 domainspecificCourse;
        uint256 domainSpecificGrade;
        //Capstone Course;
        uint256 capstoneCourse;
        uint256 capstoneGrade;

    }

    address public chairPerson; //The deployer of the contract
    mapping (address => Student) public registeredStudents; // A mapper between student anon identity and student structure.

    //Event
    event preRequisiteSatisfied (uint256 personNumber);
    event coreCoursesSatisfied (uint256 personNumber);
    event GPARequirementSatisfied (uint256 personNumber);
    event projectRequirementSatisfied (uint256 personNumber);
    event domainRequirementSatisfied (uint256 personNumber);
    event GPA(uint256 result);

    //Modifiers
    modifier checkStudent (uint256 personNumber) {
        //Check to see if the student has been registered or not.
        require ( registeredStudents[msg.sender].personNumber == 0, "Student has already registered");
        _;
    }

    modifier validStudent() {
        //Check to see if the student have a valid personNumber.
        require(registeredStudents[msg.sender].personNumber > 0, "Invalid student");
        _;
    }

    modifier isChairPerson () {
        require(chairPerson == msg.sender, "Not a chairPerson");
        _;
    }

    constructor () public {
        chairPerson = msg.sender;
    }

    function registerStudent (uint256 personNumber) public checkStudent(personNumber) {
        //Student registers by linking their university person number to their anon id
        registeredStudents[msg.sender].personNumber = personNumber;
    }

    function loginStudent(uint256 personNumber) public view returns (bool) {
        //compares the inputted number to the already registered number. If they match, grant access.
        if (registeredStudents[msg.sender].personNumber == personNumber) {
            return true;
        }else {
            return false;
        }
    }

    function addPrequisiteCourse (uint256 courseNumber, uint256 grade) public validStudent {
       /**
       check if the supplied course numbers are prerequisite courses(115 and 116 are), 
       if they are update the student structure by putting in the grades.
        */
        if (courseNumber == 115) {
            registeredStudents[msg.sender].prereq115 = grade;
        }else if (courseNumber == 116) {
            registeredStudents[msg.sender].prereq116 = grade;
        }
    }

    function addCoreCourse(uint256 courseNumber, uint256 grade) public validStudent{
        if (courseNumber == 250){
            registeredStudents[msg.sender].core250 = grade;
        }else if (courseNumber == 486){
            registeredStudents[msg.sender].core486 = grade;
        }else if (courseNumber == 487) {
            registeredStudents[msg.sender].core487 = grade;
        }else {
            revert ("Invalid course information Provide");
        }
    }

    function addDomainSpecificCourse (uint256 courseNumber, uint256 grade) public validStudent {
        /**
            Because it is a domain specific course, that is why we have a domainSpecificCourse
            domainSpecificGrade variables. They differ from persons to persons.
         */
        // courseNumber is uint hence negetive number will underflow.
        require(courseNumber < 1000, "Invalid course information provided");
        registeredStudents[msg.sender].domainspecificCourse = courseNumber;
        registeredStudents[msg.sender].domainSpecificGrade = grade;
    }

    function addCapstoneCourse (uint256 courseNumber, uint256 grade) public validStudent {
        // courseNumber is uint hence negetive number will underflow.
        require(courseNumber < 1000, "Invalid course information provided");
        registeredStudents[msg.sender].capstoneCourse = courseNumber;
        registeredStudents[msg.sender].capstoneGrade = grade;
    }

    function checkEligibility (uint256 personNumber) public validStudent returns (bool) {
        bool preRequisitesSatisfied = false;
        bool coreSatisfied = false;
        bool domainSpecificSatisfied = false;
        bool capstoneSatisfied = false;
        bool gradeSatisfied = false;
        uint256 totalGPA = 0;

        //We will assume that the pass grade is 0.
        //all grades greater than pass grade signify valid courses without fail grade.
        if (
            registeredStudents[msg.sender].prereq115 > 0 &&
            registeredStudents[msg.sender].prereq116 > 0
        ){
            preRequisitesSatisfied = true;
            emit preRequisiteSatisfied(personNumber);
            totalGPA += registeredStudents[msg.sender].prereq115 + registeredStudents[msg.sender].prereq116;
        }

        if (
            registeredStudents[msg.sender].core250 > 0 &&
            registeredStudents[msg.sender].core486 > 0 &&
            registeredStudents[msg.sender].core487 > 0 
        ){
            coreSatisfied = true;
            emit coreCoursesSatisfied(personNumber);
            totalGPA +=
                registeredStudents[msg.sender].core250 +
                registeredStudents[msg.sender].core486 +
                registeredStudents[msg.sender].core487;
        }

        // domainSpecificGrade > 0 signifies valid course.
        if (registeredStudents[msg.sender].domainSpecificGrade > 0){
            domainSpecificSatisfied = true;
            emit domainRequirementSatisfied(personNumber);
            totalGPA += registeredStudents[msg.sender].domainSpecificGrade;
        }

        // capstoneGrade > 0 signifies valid course.
        if (registeredStudents[msg.sender].capstoneGrade > 0) {
            capstoneSatisfied = true;
            emit projectRequirementSatisfied(personNumber);
            totalGPA += registeredStudents[msg.sender].capstoneGrade;
        }

        if (
            preRequisitesSatisfied &&
            coreSatisfied &&
            domainSpecificSatisfied &&
            capstoneSatisfied
        ) {
            totalGPA /=7;
            emit GPA(totalGPA);

            if (totalGPA >= MINIMUM_GPA_REQUIRED){
                gradeSatisfied = true;
                emit GPARequirementSatisfied(personNumber);
            }
        }

        return gradeSatisfied;
    }

    //Function to destroy the contract
    function destroy() public isChairPerson {
        selfdestruct(msg.sender);
    }

}