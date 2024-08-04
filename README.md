# GamblingSite
The code, written in Bash, implements security measures for a hypothetical betting website. In this context, to register on the website, users must first obtain an up-to-date version of the Green Pass from the MDS, and only then can they complete the registration process. There are three phases:

1) The MDS must contain a text file with information about your account. For example, in the MDS directory, there are files such as asd, poi and dsa that contain information about three different individuals.

2) Next, the registration and hypothetical access to the website take place securely. This phase is executed via the main.sh file. An example of execution would be: "./main.sh person1 person2...", where person can refer to, for instance, the previously mentioned asd.

3) The gameplay phase occurs through the execution of the gioco.sh script: "./gioco.sh person1 person2...." The server also participates in the game, thus becoming an active participant.

Each phase is characterized by various encryption and hashing procedures and the use of blockchain technology. The openssl commands were used to implement these features.
Important: To ensure proper functionality, it is necessary to download the package containing the xxd command.
