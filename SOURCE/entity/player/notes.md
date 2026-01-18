# Player Physics and Collision Notes
This document outlines the key concepts and implementations related to player physics and collision detection in the Presto Framework. It serves as a reference and list of expectations for the development and maintenance of these systems.

## What happened to Player Physics and Collision?
### Negatives from Previous Implementation
Four attempts were made to implement player physics and collision detection, each with its own set of challenges:
1. The first attempt was overly complex and difficult to maintain. Player would get stuck in walls frequently. It also didn't feel very good to play.
2. The second was on its way to being functional but it was severely lacking in features and polish. Movement on slopes sometimes wouldn't work properly.
3. The third attempt was similar to the first, but with added features. However, it still suffered from maintainability issues and occasional bugs. This was the best of the four attempts.
4. The fourth attempt was the least promising, with many features missing and a lack of polish. It was clear that a different approach was needed.

### Positives from Previous Implementation
Despite the challenges, there were some positive aspects:
- The first attempt felt clean. Despite its complexity, the code structure was well-organized.
- The second attempt had a solid foundation for future improvements.
- The third attempt introduced useful features that could be built upon.
- The fourth attempt highlighted the need for a more streamlined approach.

### Current Approach
We're still going to use Claude Code to handle player physics and collision detection, but with a focus on simplicity and maintainability. The goal is to create a system that is easy to understand, modify, and extend in the future. All the variables are defined in "player-var.h" for easy access and modification.

If we follow the SPG to the letter, we should be able to create a solid foundation for player physics and collision detection that can be built upon in future iterations.

## Things to Watch For
The four attempts have taught us several lessons that we should keep in mind moving forward:
- Keep it simple: Avoid unnecessary complexity that can make the code difficult to maintain.
- Keep wall collisions robust; ensure the player doesn't get stuck in walls.
- Character rotation should be smooth and responsive; this is crucial for a good player experience.
- Slope handling needs to be reliable; the player should be able to move up and down slopes without issues.
- Test thoroughly: Regular testing is essential to catch bugs and ensure the system works as intended.
- Document the code: Clear documentation will help future developers understand the system and make modifications

## Notes to Claude
- Focus on creating a clean and maintainable codebase.
- Prioritize player experience; the controls should feel responsive and intuitive.
- Ensure that the physics and collision systems are modular, allowing for easy updates and improvements in the future.
- Regularly review and refactor the code to keep it efficient and effective.
- Communicate any challenges or ideas for improvement; collaboration is key to success.
- Default to Sonic 1/2/CD style physics unless otherwise specified.
- Make sure to handle edge cases, such as corner collisions and high-speed movement.
- Consider future features that may require changes to the physics or collision systems, and design with flexibility in mind.
- Don't modify the variables too frequently; keep them stable unless absolutely necessary.
- Remember that the camera has its own propeties as well.
- Keeping it simple is the most important thing. The more complex it gets, the more unstable, and the less maintainable it becomes. It also becomes harder to keep a hold of you. 
- Accuracy is important. Regardless of performance, the player should always behave predictably and consistently.
- READ THE SPG! IT'S YOUR FRIEND!

This is all good and well, but the most important thing is to create a system that feels good to play. The player experience should always be the top priority. Espcecially when it comes to physics and collision detection.

Attempt number five, here we come!