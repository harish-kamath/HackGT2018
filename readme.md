### NOTE: The Azure and Google Cloud API service accounts we set up were quickly shut down after the competition to prevent anyone from using our account APIs. If you want to use this project, you will have to enter your own Azure and Cloud API keys.

https://devpost.com/software/vocapture

## Inspiration
We started off exploring the idea of handwriting detection in order to help aid students with language acquisition and written skills. We decided to broaden the scope of the problem to include anyone looking to learn English in a less traditional manner and who can benefit from object to text recognition. This also includes those who disabled, like the deaf as they get do not get to hear the word being pronounced and need some way to associate the word to the object. With a current shortage of English teachers, this app will help solve an essential problem in education as it will give more people an opportunity to develop their language ability.

**By 2020, 2 billion people will be learning English across the world!!!**

## What it does
Since many people do not have access to bilingual teachers or resources there must be a better way to teach the general populous of active learners. And most people with a teacher learn by going through a textbook rather than the items they encounter on a day to day basis. We wanted to provide students with a way to learn about the language with everyday objects.

## How we built it
Items will be boxed and will be labeled based on what they are. The student will be given the word and will need to write out the word correctly in order for it to be deemed correct. Spelling and handwriting are critical elements to being correct so be mindful of those elements. After 1 correct answer, the answer while writing goes away, after 3, the name during the object detection goes away, and after 5, a green box appears on the object when detected. Gamification aspect entails progressing through levels of proficiency, achieving all green boxes, and each level there are a number of words that will get you to a 100% for that level, goes from basic to advanced. Got to this metric because I wanted to incentivize the finishing of this project as it would be more encouraging to see 20% of level 1 vs 0.0116% of the entire English language.

## Challenges we ran into
Worked through different methodologies of tackling the problem, thought about using OCR (optical character recognition) or even Google’s vision API. Just did not seem to be working well or was not suited for our situation since the problem required a more reliable and more efficient way to verify the text.

## Accomplishments that we're proud of
We were able to box over 25 different types of objects and were able to integrate multiple different types of features such as multiple languages and a gamification aspect to have the user enjoy the experience of learning a new language.

## What we learned
We learned how to use Azure and Google Cloud through our process. Text Recognition on the Computer Vision API through Azure to recognize the handwriting to help the students learn. We used the Google Cloud Translate API option for multiple languages options. We also used these technologies along with a couple of others in order to create the technically competent stack we have right now.

## What's next for Vocapture
VoCoins to add coins to help with hints. These coins will be useful in later levels as getting one wrong would drop you down to a 0. A more expansive dataset for more object detection. Multi-platform usage to introduce an Android app. Achievements and social media implementations for added incentives to keep learning the language. To gain traction for the app as well as get quick and easy user input we would push this app to our local elementary/primary school and see how younger students react to using the app as well as English to Speaking Other Language (ESOL) students for research on ways to improve our app.

