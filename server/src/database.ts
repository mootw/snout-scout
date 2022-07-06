import { MatchEvent, PitSurveyItem } from "./season";


export interface DataStore {
    version: number;
    events: Record<string, FrcEvent>;
}

export interface FrcEvent {
    name: string;
    teams: number[];
    matches: Match[];
    pit_scouting: Record<string, PitSurveyResult>;
}

export interface PitSurveyResult {
    team: number;
    time: string;
    scout: string;
    survey: PitSurveyItem[];
}

export interface Match {
    section: string;
    number: number;
    scheduled_time: string;
    blue: number[];
    red: number[];
    id: string;
    results?: MatchResults;
    timelines: Record<string, MatchTimeline>
}

export interface MatchResults {
    scout: string;
    time: string;
    start_time: string;
    red: Record<string, string>;
    blue: Record<string, string>;
}

export interface MatchTimeline {
    scout: string;
    time: string;
    events: MatchEvent[];
}