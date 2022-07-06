

export interface Season {
    season: string;
    pit_scouting: PitScouting;
    match_scouting: MatchScouting;
}

export interface PitScouting {
    survey: PitSurveyItem[];
}

export interface PitSurveyItem {
    id: string;
    type: string;
    label: string;
    value?: any; //Value of survey result, can be anything
    options?: string[];
}

export interface MatchScouting {
    pregame: PitSurveyItem[];
    auto: MatchEvent[];
    teleop: MatchEvent[];
    endgame: MatchEvent[];
    postgame: PitSurveyItem[];
}

export interface MatchEvent {
    id: string;
    label: string;
    type: string;
    points: number;
    rp: number;
}