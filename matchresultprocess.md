# Match Result Process
This file is the out of code documentation for MatchResultsProcess.

snout scout uses [https://pub.dev/packages/eval_ex](https://pub.dev/packages/eval_ex) to parse and run math expressions to maximize the customization of the app. In the future there might be support for full code execution using https://pub.dev/packages/dart_eval (and flutter_eval for fully custom data views) however there are potential security implications and the setup is much more complex to debug requiring programming experience. These options will likely exist side-by-side.


## Syntax
When editing a process in JSON, `""` may require escaping. For example: `EVENT(\"id\")`

Otherwise math syntax applies. If your process is empty in the app (or all zeros) there was likely to be a syntax error. Internally the errors are being tracked verbosely, but currently they are not displayed in the app. (https://github.com/mootw/snout-scout/issues/2)

# Example Processes

## Displaying the quantity of an event.
A typical process might involve displaying how many of an event occurred:

`EVENT("fumble")`

For example there are 2 scoring locations for a game piece, and we want to display how many of that game piece was scored regardless of 'level':

`EVENT("ball_high")+EVENT("ball_low")`

Another example might be that we want to see how much a robot does something in auto. We could even filter for robots that intake more than 2 pieces in auto and score at least 1 ball high:

`AUTOEVENT("intake") > 2 && AUTOEVENT("ball_high") >= 2`

## Calculating scoring
You may want to calculate a teams impact. Here is a way to calculate scoring. Firstly we can add up all of the events in auto and in teleop and multiply it by the points for each scoring piece. It might look like this. This process might have the id of "ball_score":

`(AUTOEVENT("balls_high")*4)+(TELEOPEVENT("balls_high")*2)`

We could caclulate auto_movement by checking if the number of robot_position events is greater than zero in a certain region in auto. returning 1 or 0 and then multiply it by scoring later:

`AUTOEVENTINBBOX("robot_position",-0.42,-1,0.42,1) > 0`

Lastly we can calculate the climb_score by getting post game data and doing some clever math. This will return 0 if none match since 0 + 0 + 0 = 0:

`(POSTGAMEIS("climb_level", "High") * 15) + (POSTGAMEIS("climb_level", "Medium") * 10) + (POSTGAMEIS("climb_level", "Low") * 5)`

The final score might be calculated as:

`PROCESS("climb_score") + PROCESS("ball_score") + (PROCESS("auto_movement") * 3)`

## Calculating 'Pickability'

In this example we will use previous metrics and even pit scouting metrics to determine the 'pickability' of a team to assist in alliance selection. In this example, our strategy this year involves a partner climb. So we made these our goals:
- positive bias robots that can climb reliabilty to high and are compatible with our climbing mechanism (via pit scouting data). 
- negative bias robots that regularly drop things, so we will subtract the amount of fumbles with a bias
- positive bias robots that appear to have aware drivers.

We will create a separate driving_score_bias process to simplify the pickability expression:

`(POSTGAMEIS("driving_awareness", "High") * 15) + (POSTGAMEIS("driving_awareness", "Medium") * 0) + (POSTGAMEIS("driving_awareness", "Low") * -10)`

Our final 'pickability' expression looks like this. We might create multiple different pickability expressions with different biases or focuses:

`PROCESS("score") + ((POSTGAMEIS("climb_level", "High") && PITSCOUTINGIS("climb_compatible", "true")) * 20) - (EVENT("fumble") * 10) + PROCESS("driving_score_bias")`


# Functions and Variables
There are no pre-defined variables at the moment.

> **NOTE** Potentially in the future there will be variables for each team number, and lookup functions based on team number; or a more capable matchevent query system. There also might be a value lookup for survey items rather than just an equals function.

## snout scout functions

| Function | Description |
|----------|-------------|
| PITSCOUTINGIS ("id", "value") | Returns 1 if the team's pit scouting data matches 0 otherwise |
| POSTGAMEIS ("id", "value") | Returns 1 if a post game survey item matches the value 0 otherwise |
| EVENTINBBOX("id", minX, minY, maxX, maxY) | Returns number of events with a specific id within a bbox (uses interpolated timeline) |
| AUTOEVENTINBBOX("id", minX, minY, maxX, maxY) | Returns number of auto events with a specific id within a bbox (uses interpolated timeline) |
| TELEOPEVENTINBBOX("id", minX, minY, maxX, maxY) | Returns number of teleop events with a specific id within a bbox (uses interpolated timeline) |
| EVENT("id") | adder that counts the number of a specific event |
| AUTOEVENT("id") | adder that counts the number of a specific event during auto |
| TELEOPEVENT("id") | adder that counts the number of a specific event during teleop |
| PROCESS("id") | calls another process by id and returns the value |

## [eval_ex built in functions](https://github.com/RobluScouting/EvalEx#built-in-functions-and-operators)

| Function             | Description                                                                       |
|----------------------|-----------------------------------------------------------------------------------|
| +                    | Addition                                                                          |
| -                    | Subtraction                                                                       |
| *                    | Multiplication                                                                    |
| /                    | Division                                                                          |
| %                    | Modulus                                                                           |
| ^                    | Power                                                                             |
| &&                   | Returns 1 if both expressions are true, 0 otherwise                               |
| \|\|                 | Returns 1 if either or both expressions are true, 0 otherwise                     |
| >                    | Returns 1 if the left expression is greater than the right                        |
| >=                   | Returns 1 if the left expression is greater than or equal to the right            |
| <                    | Returns 1 if the right expression is greater than the left                        |
| <=                   | Returns 1 if the right expression is greater than or equal to the left            |
| =                    | Returns 1 if the left and right expressions are equal                             |
| ==                   | Returns 1 if the left and right expressions are equal                             |
| !=                   | Returns 1 if the left and right expressions are NOT equal                         |
| <>                   | Returns 1 if the left and right expressions are NOT equal                         |
| STREQ("str1","str2") | Returns 1 if the literal "str1" is equal to "str2", otherwise returns 0           |
| FACT(int)            | Computes the factorial of arg1                                                    |
| NOT(expression)      | Returns 1 if arg1 evaluates to 0, otherwise returns 0                             |
| IF(cond,exp1,exp2)   | Returns exp1 if cond evaluates to 1, otherwise returns exp2                       |
| Random()             | Returns a random decimal between 0 and 1                                          |
| SINR(exp)            | Evaluates the SIN of exp, assuming exp is in radians                              |
| COSR(exp)            | Evaluates the COS of exp, assuming exp is in radians                              |
| TANR(exp)            | Evaluates the TAN of exp, assuming exp is in radians                              |
| COTR(exp)            | Evaluates the COT of exp, assuming exp is in radians                              |
| SECR(exp)            | Evaluates the SEC of exp, assuming exp is in radians                              |
| CSCR(exp)            | Evaluates the CSC of exp, assuming exp is in radians                              |
| SIN(exp)             | Evaluates the SIN of exp, assuming exp is in degrees                              |
| COS(exp)             | Evaluates the COS of exp, assuming exp is in degrees                              |
| TAN(exp)             | Evaluates the TAN of exp, assuming exp is in degrees                              |
| COT(exp)             | Evaluates the COT of exp, assuming exp is in degrees                              |
| SEC(exp)             | Evaluates the SEC of exp, assuming exp is in degrees                              |
| CSC(exp)             | Evaluates the CSC of exp, assuming exp is in degrees                              |
| ASINR(exp)           | Evaluates the ARCSIN of exp, assuming exp is in radians                           |
| ACOSR(exp)           | Evaluates the ARCCOS of exp, assuming exp is in radians                           |
| ATANR(exp)           | Evaluates the ARCTAN of exp, assuming exp is in radians                           |
| ACOTR(exp)           | Evaluates the ARCCOT of exp, assuming exp is in radians                           |
| ATAN2R(exp1, exp1)   | Evaluates the ARCTAN between exp1 and exp2, assuming exp1 and exp2 are in radians |
| ASIN(exp)            | Evaluates the ARCSIN of exp, assuming exp is in degrees                           |
| ACOS(exp)            | Evaluates the ARCCOS of exp, assuming exp is in degrees                           |
| ATAN(exp)            | Evaluates the ARCTAN of exp, assuming exp is in degrees                           |
| ACOT(exp)            | Evaluates the ARCCOT of exp, assuming exp is in degrees                           |
| ATAN2(exp1, exp1)    | Evaluates the ARCTAN between exp1 and exp2, assuming exp1 and exp2 are in degrees |
| RAD(deg)             | Converts deg to radians                                                           |
| DEG(rad)             | Converts rad to degrees                                                           |
| MAX(a,b,...)         | Returns the maximum value from the provided list of 1 or more expressions         |
| MIN(a,b,...)         | Returns the minimum value from the provided list of 1 or more expressions         |
| ABS(exp)             | Returns the absolute value of exp                                                 |
| LOG(exp)             | Returns the natural logarithm of exp                                              |
| LOG10(exp)           | Returns the log base 10 of exp                                                    |
| ROUND(exp,precision) | Returns exp rounded to precision decimal points                                   |
| FLOOR(exp)           | Returns the floor of exp                                                          |
| CEILING(exp)         | Returns the ceiling of exp                                                        |
| SQRT(exp)            | Computes the square root of exp                                                   |
| e                    | Euler's number                                                                    |
| PI                   | Ratio of circle's circumference to diameter                                       |
| NULL                 | Alias for null                                                                    |
| TRUE or true         | Alias for 1                                                                       |
| FALSE or false        | Alias for 0                                                                       |