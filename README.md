# OWASP Testing Guide Tool

Script for executing tests from the OWASP Testing Guide to check for Vulnerabilities

## Automated tools

The idea of the script is to provide automated tools for the following parts:

- Footprinting (checking information disclosure for both http and https netcat commands)
- Information gathering about possible open port and vulnerabilities with nmap
- Web application enumeration using wget to act as a spider in order to check every possible sublink

### TODO

Add test for weak cryptography.
Add a brute force tester for the home page
Check cookies for possible weak session managememnt
Add a tester for possible sql injection and xss
Check for other vulnerabilities

## One final note

The purpose of this script is to help testers and companies to test their web application for possible vulnerabilities without the need of extensive knowledge. It does not, in any way substitute a formed tester or programmer.
